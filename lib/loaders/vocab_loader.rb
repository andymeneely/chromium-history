require 'oj'

class VocabLoader

  def initialize
    @tmp_dir = Rails.configuration.tmpdir
    @data_dir = Rails.configuration.datadir
  end

  def load
    raw = @tmp_dir+'/raw_messages.txt'
    Message.get_all_messages raw
    VocabLoader.clean_file raw, @tmp_dir+'/messages.txt'
    File.unlink raw
    acm_corpus = Corpus.new "#{@data_dir}/acm/raw_acm.txt"
    message_corpus = Corpus.new "#{@tmp_dir}/messages.txt"
    acm_corpus.filter
    message_corpus.filter
    words = message_corpus.word_intersect acm_corpus.words
    block = lambda do |table|
      words.each do |word|
        table << [word]
      end
    end
    vocab_file = "#{@tmp_dir}/vocab.csv"
    PsqlUtil.create_upload_file vocab_file, &block
    PsqlUtil.copy_from_file 'technical_words', vocab_file
    PsqlUtil.add_auto_increment_key 'technical_words'
  end

  def reassociate_messages
    reassociate 'messages', 'text', 'messages_technical_words'
    PsqlUtil.add_index 'messages_technical_words', 'message_id', 'hash'
    PsqlUtil.add_index 'messages_technical_words', 'technical_word_id', 'hash'
  end

  def reassociate target_table, searchable_field, linking_table
    tmp_file = "#{@tmp_dir}/copy_tmp.csv"
    query = " 
      SELECT 
        a.id, 
        t.id 
      FROM 
        #{target_table} a, 
        technical_words t 
      WHERE 
        to_tsvector('english', a.#{searchable_field}) @@ to_tsquery(t.word)
     "
    PsqlUtil.copy_to_file query, tmp_file
    PsqlUtil.copy_from_file linking_table, tmp_file
  end

  def self.clean_file target_file, output_file
    file = File.open target_file, 'r'
    new_file = VocabLoader.remove_quoted_comments file.read
    new_file = VocabLoader.clean_comment_messages new_file
    new_file = VocabLoader.remove_uris new_file
    new_file = VocabLoader.trim_whitespace new_file
    new_file = VocabLoader.remove_nonword new_file
    File.open(output_file, 'w+') { |file| file.write(new_file) }
  end

  def self.clean string
    string = VocabLoader.remove_quoted_comments string
    string = string.gsub(/^http[^\s]*$/, '')
    string = string.gsub(/^On.*wrote:$/, '')
    string = VocabLoader.remove_nonword string
    VocabLoader.trim_whitespace string
  end

  def self.clean_messages string
    new_file = VocabLoader.remove_quoted_comments string
    new_file = new_file.gsub(/^On.*wrote:$/, '')
  end

  def self.clean_comment_messages string
    string.gsub(/https?:\/\/codereview.chromium.org\/\d+\/diff[\/\.\w]+\\n(Line \d+:|File [\/\w\.]+ \((right|left)\):)/, '')
  end
  
  def self.remove_quoted_comments string
    string.gsub(/^\>.*$/, '')
  end

  def self.remove_uris string
    string.gsub(/^(?:#{ URI.scheme_list.keys.join('|') })/i, '')
  end

  def self.trim_whitespace string
    string.gsub(/[\s{2,}]/, ' ')
  end 

  def self.remove_nonword string
    string.gsub(/[^\w\s]/, '')
  end
end
