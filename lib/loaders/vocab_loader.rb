require 'oj'

class VocabLoader

  def initialize
    @tmp_dir = Rails.configuration.tmpdir
  end

  def load
    acm_corpus = Corpus.new "#{@tmp_dir}/raw_acm.txt"
    comment_corpus = Corpus.new "#{@tmp_dir}/raw_comments.txt"
    comment_corpus.filter
    words = comment_corpus.word_intersect acm_corpus.words
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
      clean = VocabLoader.remove_quoted_comments(convo['string_agg']).gsub("'", "")
      result = tree.search clean
      if result
        table << [convo['author_id'], result['id']]
      end
    end
    table.fsync
    ActiveRecord::Base.connection.execute "COPY developers_technical_words FROM '#{@tmp_dir}/dev_words.csv' DELIMITER ',' CSV"
  end


  def associate_code_review_vocab
    table = CSV.open "#{@tmp_dir}/code_review_words.csv", 'w+'
    allwords = ActiveRecord::Base.connection.execute "SELECT * FROM technical_words"
    tree = LazyBinarySearchTree.new allwords.map {|word| word}
    convos = Comment.get_all_convo
    convos.each do |convo| 
      clean = VocabLoader.remove_quoted_comments(convo['string_agg']).gsub("'", "")
      result = tree.search clean
      if result
        table << [convo['code_review_id'], result['id']]
      end
    end
    table.fsync
    ActiveRecord::Base.connection.execute "COPY code_reviews_technical_words FROM '#{@tmp_dir}/code_review_words.csv' DELIMITER ',' CSV"
  end

	
	
  def self.remove_file_quoted_comments target_file
    file = File.open target_file, 'r'
    new_file = VocabLoader.remove_quoted_comments file.read
    file.fsync
    file.close
    File.open(target_file, 'w+') { |file| file.write(new_file) }
  end

  def self.remove_quoted_comments string
    string.gsub(/^[\<|\>].*$/, '')
  end
end
