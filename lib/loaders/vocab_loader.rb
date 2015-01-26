require 'oj'

class VocabLoader

  def initialize
    @tmp_dir = Rails.configuration.tmpdir
    @data_dir = Rails.configuration.datadir
    allwords = ActiveRecord::Base.connection.execute "SELECT * FROM technical_words"
    @search_tree = LazyBinarySearchTree.new allwords.map {|word| word}
  end

  def load
    raw = @tmp_dir+'/raw_comments.txt'
    Comment.get_all_convo raw
    VocabLoader.clean_file raw, @tmp_dir+'/comments.txt'
    File.unlink raw
    raw = @tmp_dir+'/raw_messages.txt'
    Message.get_all_messages raw
    VocabLoader.clean_file raw, @tmp_dir+'/messages.txt'
    File.unlink raw
    acm_corpus = Corpus.new "#{@data_dir}/raw_acm.txt"
    comment_corpus = Corpus.new "#{@tmp_dir}/comments.txt"
    message_corpus = Corpus.new "#{@tmp_dir}/messages.txt"
    comment_corpus.filter
    message_corpus.filter
    words = comment_corpus.word_intersect acm_corpus.words
    words = words + message_corpus.word_intersect(acm_corpus.words)
    block do |table|
      words.each do |word|
        table << [word]
      end
    end
    copy_results "#{@tmp_dir}/vocab.csv", 'technical_words', block
    ActiveRecord::Base.connection.execute "ALTER TABLE technical_words ADD COLUMN id SERIAL; ALTER TABLE technical_words ADD PRIMARY KEY (id);"
  end

  def associate_developer_vocab
    block do |table|
      convos = Comment.get_developer_comments
      table = reassociate convos, 'author_id', 'string_agg', table
      convos.clear
      messages = Message.get_developer_messages
      table = reassociate messages, 'sender_id', 'string_agg', table
      messages.clear
    end
    copy_results "#{@tmp_dir}/dev_words.csv", 'developers_technical_words', block
  end

  def associate_code_review_vocab
    block do |table|
      convos = Comment.get_all_convo
      table = reassociate convos, 'code_review_id', 'string_agg', table
      convos.clear
      messages = Message.get_all_messages
      table = reassociate convos, 'code_review_id', 'string_agg', table
      messages.clear
    end
    copy_results "#{@tmp_dir}/code_review_words.csv", 'code_reviews_technical_words', block
  end

  def copy_results file_name, table_name, &block
    table = CSV.open "#{file_name}", 'w+'
    block.call table
    table.fsync
    ActiveRecord::Base.connection.execute "COPY #{table_name} FROM '#{file_name}' DELIMITER ',' CSV"
  end

  def reassociate origins, origin_id_key, origin_text_key, table
    origins.each do |origin|
      clean = VocablLoader.clean origin[origin_text_key]
      results = @search_tree.search clean
      results.each do |result|
        table << [origin[origin_id_key], result.id]
      end
    end
    table
  end

  def self.clean_file target_file, output_file
    file = File.open target_file, 'r'
    new_file = VocabLoader.remove_quoted_comments file.read
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
