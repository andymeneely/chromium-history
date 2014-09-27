class VocabLoader

  def initialize
    @tmp_dir = Rails.configuration.tmpdir
  end

  def load
    vocab_file = @tmp_dir+'/vocab.txt'
    Comment.new.get_all_convo vocab_file
    remove_quoted_comments vocab_file, @tmp_dir+'/clean_vocab.txt'

    # Use NLTK to parse text and 
    res = `python lib/nlp/python/plain_text_word_diff.py #{@tmp_dir}/ clean_vocab.txt`
    words = Oj.load(res)
    vocabCopy = CSV.open @tmp_dir + '/vocab.csv', 'w+'
    words.each do |word|
      vocabCopy << [word]
    end
    vocabCopy.fsync
    ActiveRecord::Base.connection.execute "COPY technical_words FROM '#{@tmp_dir}/vocab.csv' DELIMITER ',' CSV"
    ActiveRecord::Base.connection.execute "ALTER TABLE technical_words ADD COLUMN id SERIAL; ALTER TABLE technical_words ADD PRIMARY KEY (id);"
  end

  def associate_developer_vocab
    conversations = Comment.new.get_developer_comments
    author_comments = {}
    conversations.each do |conversation|
      authorComments[conversation['author_id']] = conversation['string_agg']
    end

    File.open("#{tmp_dir}/vocab/devs.json", 'w+') { |file| file.write(Oj.dump(author_comments)) }
    res = `python lib/nlp/python/json_word_diff.py #{tmp_dir}/vocab/devs.json`
  end

  def associate_code_review_vocab
    conversations = Comment.new.get_all_convo
    code_review_comments = {}
    conversations.each do |conversation|
      code_review_comments[conversation['code_review_id']] = conversation['string_agg']
    end

    File.open("#{tmp_dir}/vocab/revs.json", 'w+') { |file| file.write(Oj.dump(code_review_comments)) }
  end

  def remove_quoted_comments target_file, result_file
    file = File.open target_file, 'r'
    newFile = file.read.gsub(/^\<.*$/, '')
    File.open(result_file, 'w+') { |file| file.write(newFile) }
  end
end
