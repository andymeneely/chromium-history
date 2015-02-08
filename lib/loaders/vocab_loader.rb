require 'oj'

class VocabLoader

  def initialize
    @tmp_dir = Rails.configuration.tmpdir
    @data_dir = Rails.configuration.datadir
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
    acm_corpus = Corpus.new "#{@data_dir}/acm/raw_acm.txt"
    comment_corpus = Corpus.new "#{@tmp_dir}/comments.txt"
    message_corpus = Corpus.new "#{@tmp_dir}/messages.txt"
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
    agg_csv vocab_file, &block
    copy_results vocab_file, 'technical_words'
    ActiveRecord::Base.connection.execute "ALTER TABLE technical_words ADD COLUMN id SERIAL; ALTER TABLE technical_words ADD PRIMARY KEY (id);"
  end

  def reassociate_comments
    reassociate 'comments', 'text', 'comments_technical_words'
  end

  def reassociate_messages
    reassociate 'messages', 'text', 'messages_technical_words'
  end

  def reassociate target_table, searchable_field, linking_table
    tmp_file = "#{@tmp_dir}/copy_tmp.csv"
    sql = <<-eos 
      COPY (
        SELECT 
          a.id, 
          t.id 
        FROM 
          #{target_table} a, 
          technical_words t 
        WHERE 
          to_tsvector('english', a.#{searchable_field}) @@ to_tsquery(t.word)
      ) TO #{tmp_file} WITH (FORMAT CSV)
      eos
    ActiveRecord::Base.connection.execute sql
    copy_results 
    ActiveRecord::Base.connection.execute "COPY #{linking_table} FROM #{tmp_file} DELIMITER ',' CSV"
  end

  # iterate through block to fill csv table file
  def agg_csv file_name, &block
    table = CSV.open "#{file_name}", 'w+'
    block.call table
    table.fsync
  end

  # Use Psql's copy function to upload csv to db
  def copy_results file_name, table_name
    ActiveRecord::Base.connection.execute "COPY #{table_name} FROM '#{file_name}' DELIMITER ',' CSV"
  end

  def self.add_fulltext_search_index table_name, searchable_field
    ActiveRecord::Base.connection.execute "CREATE INDEX #{table_name}_search ON #{table_name} USING gin(to_tsvector('english', #{searchable_field}));"
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
