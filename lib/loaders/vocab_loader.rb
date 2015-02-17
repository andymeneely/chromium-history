require 'oj'

class VocabLoader

  def initialize
    @tmp_dir = Rails.configuration.tmpdir
    @data_dir = Rails.configuration.datadir
  end

  def parse_scrape_results
    acm_scrape = Oj.load_file "#{@data_dir}/acm/acm.json"
    puts acm_scrape['pages'].size
    raw = "#{@data_dir}/acm/raw_acm.txt"
    File.open raw, 'w+' do |file|
      acm_scrape['pages'].each do |page|
        file.write page['results']['abstracts'].strip
        file.write "\n"
      end
      file.fsync
    end
    @categories = Hash.new
    PsqlUtil.create_upload_file "#{@tmp_dir}/categories.csv" do |table|
      acm_scrape['pages'].each do |page|
        page['results']['categories'].each do |category|
          cat_name = category['category'].strip
          @categories[cat_name] ||= []
          @categories[cat_name] << page['results']['abstracts']
        end
      end
      @categories.each_key do |category|
        table << [category]
      end
    end    
  end

  def load
    PsqlUtil.copy_from_file 'acm_categories', "#{@tmp_dir}/categories.csv"
    PsqlUtil.add_auto_increment_key 'acm_categories'
    raw = @tmp_dir+'/raw_comments.txt'
    Comment.get_all_convo raw
    VocabLoader.clean_file raw, @tmp_dir+'/comments.txt'
    File.unlink raw
    raw = @tmp_dir+'/raw_messages.txt'
    Message.get_all_messages raw
    VocabLoader.clean_file raw, @tmp_dir+'/messages.txt'
    File.unlink raw
    acm_corpus = Corpus.new "#{@data_dir}/acm/raw_acm.txt"
    comment_corpus = Corpus.new "#{@tmp_dir}/comments.txt"
    message_corpus = Corpus.new "#{@tmp_dir}/messages.txt"
    acm_corpus.filter
    comment_corpus.filter
    message_corpus.filter
    words = comment_corpus.word_intersect acm_corpus.words
    words = words + message_corpus.word_intersect(acm_corpus.words)
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

  def reassociate_comments
    reassociate 'comments', 'text', 'comments_technical_words'
    PsqlUtil.add_index 'comments_technical_words', 'comment_id', 'hash'
    PsqlUtil.add_index 'comments_technical_words', 'technical_word_id', 'hash'
  end

  def reassociate_messages
    reassociate 'messages', 'text', 'messages_technical_words'
    PsqlUtil.add_index 'messages_technical_words', 'message_id', 'hash'
    PsqlUtil.add_index 'messages_technical_words', 'technical_word_id', 'hash'
  end

  def reassociate_categories
    search_tree = LazyBinarySearchTree.new(TechnicalWords.all.map {|word| word})
    file = "#{@tmp_dir}/category_vocab.csv"
    PsqlUtil.create_upload_file file do |table|
      AcmCategory.all.limit(50).each do |category|
        abstracts = @categories[category.name]
        results = search_tree.search VocabLoader.clean(abstracts.join ' ')
        results.each do |result|
          table << [category.id, result['id']]
        end
      end
    end
    PsqlUtil.copy_from_file 'acm_categories_technical_words', file
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
