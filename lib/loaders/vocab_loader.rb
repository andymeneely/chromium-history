require 'oj'

class VocabLoader

  def initialize
    @tmp_dir = Rails.configuration.tmpdir
  end

  def load
    acm_corpus = Corpus.new "#{@tmp_dir}/raw_acm.txt"
    comment_corpus = Corpus.new "#{@tmp_dir}/comments.txt"
    message_corpus = Corpus.new "#{@tmp_dir}/messages.txt"
    comment_corpus.filter
    message_corpus.filter
    words = comment_corpus.word_intersect acm_corpus.words
    words = words + message_corpus.word_intersect(acm_corpus.words)
    vocabCopy = CSV.open @tmp_dir + '/vocab.csv', 'w+'
    words.each do |word|
      vocabCopy << [word]
    end
    vocabCopy.fsync
    ActiveRecord::Base.connection.execute "COPY technical_words FROM '#{@tmp_dir}/vocab.csv' DELIMITER ',' CSV"
    ActiveRecord::Base.connection.execute "ALTER TABLE technical_words ADD COLUMN id SERIAL; ALTER TABLE technical_words ADD PRIMARY KEY (id);"
  end

  def associate_developer_vocab
    table = CSV.open "#{@tmp_dir}/dev_words.csv", 'w+'
    allwords = ActiveRecord::Base.connection.execute "SELECT * FROM technical_words"
    tree = LazyBinarySearchTree.new allwords.map {|word| word}
    convos = Comment.get_developer_comments
    convos.each do |convo| 
      clean = VocabLoader.clean(convo['string_agg'])
      result = tree.search clean
      if result
        table << [convo['author_id'], result['id']]
      end
    end
    convos.clear
    messages = Message.get_developer_messages
    messages.each do |message|
      clean = VocabLoader.clean(message['string_agg'])
      result = tree.search clean
      if result
        table << [message['sender_id'], result['id']]
      end
    end
    messages.clear
    table.fsync
    ActiveRecord::Base.connection.execute "COPY developers_technical_words FROM '#{@tmp_dir}/dev_words.csv' DELIMITER ',' CSV"
  end

  def associate_code_review_vocab
    table = CSV.open "#{@tmp_dir}/code_review_words.csv", 'w+'
    allwords = ActiveRecord::Base.connection.execute "SELECT * FROM technical_words"
    tree = LazyBinarySearchTree.new allwords.map {|word| word}
    convos = Comment.get_all_convo
    convos.each do |convo| 
      clean = VocabLoader.clean(convo['string_agg'])
      result = tree.search clean
      if result
        table << [convo['code_review_id'], result['id']]
      end
    end
    convos.clear
    messages = Message.get_all_messages
    messages.each do |message|
      clean = VocabLoader.clean(message['string_agg'])
      result = tree.search clean
      if result
        table << [message['sender_id'], result['id']]
      end
    end
    messages.clear
    table.fsync
    ActiveRecord::Base.connection.execute "COPY code_reviews_technical_words FROM '#{@tmp_dir}/code_review_words.csv' DELIMITER ',' CSV"
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
