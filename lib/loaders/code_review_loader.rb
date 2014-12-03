require 'set'
require 'csv'

class CodeReviewLoader
  
  def copy_parsed_tables 
    tmp = Rails.configuration.tmpdir
    ActiveRecord::Base.connection.execute("COPY code_reviews FROM '#{tmp}/code_reviews.csv' DELIMITER ',' CSV")
    ActiveRecord::Base.connection.execute("COPY reviewers FROM '#{tmp}/reviewers.csv' DELIMITER ',' CSV")
    ActiveRecord::Base.connection.execute("COPY patch_sets FROM '#{tmp}/patch_sets.csv' DELIMITER ',' CSV")
    ActiveRecord::Base.connection.execute("COPY patch_set_files FROM '#{tmp}/patch_set_files.csv' DELIMITER ',' CSV")
    
    begin
      ActiveRecord::Base.connection.execute("COPY messages FROM '#{tmp}/messages.csv' DELIMITER ',' CSV")
    rescue Exception => e
      $stderr.puts "COPY messages failed!" 
      $stderr.puts e.message  
      $stderr.puts e.backtrace.inspect 
    end

    begin
      ActiveRecord::Base.connection.execute("COPY comments FROM '#{tmp}/comments.csv' DELIMITER ',' CSV")
    rescue Exception => e
      $stderr.puts "COPY messages failed!" 
      $stderr.puts e.message  
      $stderr.puts e.backtrace.inspect 
    end
    
    ActiveRecord::Base.connection.execute("COPY developers FROM '#{tmp}/developers.csv' DELIMITER ',' CSV")
    ActiveRecord::Base.connection.execute("SELECT setval('developers_id_seq', (SELECT MAX(id) FROM developers)+1 )")
    ActiveRecord::Base.connection.execute("COPY participants FROM '#{tmp}/participants.csv' DELIMITER ',' CSV")
    ActiveRecord::Base.connection.execute("COPY contributors FROM '#{tmp}/contributors.csv' DELIMITER ',' CSV")
     
  end

  def add_primary_keys
    ActiveRecord::Base.connection.execute "ALTER TABLE messages ADD COLUMN id SERIAL; ALTER TABLE messages ADD PRIMARY KEY (id);"
    ActiveRecord::Base.connection.execute "ALTER TABLE comments ADD COLUMN id SERIAL; ALTER TABLE comments ADD PRIMARY KEY (id);"
    ActiveRecord::Base.connection.execute "ALTER TABLE patch_sets ADD COLUMN id SERIAL; ALTER TABLE patch_sets ADD PRIMARY KEY (id);"
    ActiveRecord::Base.connection.execute "ALTER TABLE patch_set_files ADD COLUMN id SERIAL; ALTER TABLE patch_set_files ADD PRIMARY KEY (id);"
    ActiveRecord::Base.connection.execute "ALTER TABLE reviewers ADD COLUMN id SERIAL; ALTER TABLE reviewers ADD PRIMARY KEY (id);"
    ActiveRecord::Base.connection.execute("CREATE INDEX ON code_reviews USING hash (issue)")
    ActiveRecord::Base.connection.execute "ALTER TABLE participants ADD COLUMN id SERIAL; ALTER TABLE participants ADD PRIMARY KEY (id);"
    ActiveRecord::Base.connection.execute "ALTER TABLE contributors ADD COLUMN id SERIAL; ALTER TABLE contributors ADD PRIMARY KEY (id);"      
  end

end #class
