class VocabLoader

  def initialize
    @tmp_dir = Rails.configuration.tmpdir
  end

  def load
    vocab_file = @tmp_dir+'/vocab.txt'
    Comment.new.get_all_convo vocab_file
    remove_quoted_comments vocab_file, @tmp_dir+'/clean_vocab.txt'
    corpus = Corpus.new
    comment_doc = corpus.document vocab_file
    acm_doc = corpus.document "#{Rails.configuration.datadir}/acm/raw_abstracts.txt"
    comment_corpus = corpus.create comment_doc
    acm_corpus = corpus.create acm_doc

    comment_words = []
    comment_corpus.words.each do |word|
      comment_words << word.to_s
    end

    Oj.to_file @tmp_dir+'/wordlist.json', comment_words

    # Use NLTK's built in Corpora to remove non-technical words 
    res = `python lib/nlp/python/json_word_diff.py #{@tmp_dir}/wordlist.json`
    diff_words = Oj.load(res)
    acm_words = []
    acm_corpus.words.each do |word|
      acm_words << word.to_s
    end

    words = corpus.word_intersect diff_words, acm_words
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
    words = ActiveRecord::Base.connection.execute "SELECT * FROM technical_words"

    convos = Comment.new.get_developer_comments
    convos.each do |convo| 
      clean = convo['string_agg'].gsub("'", "")
      res = ActiveRecord::Base.connection.execute %Q{ 
        SELECT to_tsvector('#{clean}') 
        @@ to_tsquery('#{words.map{|word| word['word']}.join(" | ")}')
        AS found
      }
      if(res[0]['found'] == 't') 
        words.each do |word| 
           res = ActiveRecord::Base.connection.execute %Q{ 
            SELECT to_tsvector('#{clean}') 
            @@ to_tsquery('#{word['word']}')
            AS found
          }
          if(res[0]['found'] == 't') 
            table << [convo['author_id'], word['id']]
          endpsql
        end
      end
    
    end
    table.fsync
    ActiveRecord::Base.connection.execute "COPY developers_technical_words FROM '#{@tmp_dir}/dev_words.csv' DELIMITER ',' CSV"
  end

  def remove_quoted_comments target_file, result_file
    file = File.open target_file, 'r'
    newFile = file.read.gsub(/^\<.*$/, '')
    File.open(result_file, 'w+') { |file| file.write(newFile) }
  end
end
