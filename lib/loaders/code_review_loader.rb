require 'set'
require 'csv'

class CodeReviewLoader
  
  def copy_parsed_tables 
    datadir = File.expand_path(Rails.configuration.datadir + "/tmp")
    ActiveRecord::Base.connection.execute("COPY code_reviews FROM '#{datadir}/code_reviews.csv' DELIMITER ',' CSV")
    ActiveRecord::Base.connection.execute("COPY reviewers FROM '#{datadir}/reviewers.csv' DELIMITER ',' CSV")
    ActiveRecord::Base.connection.execute("COPY patch_sets FROM '#{datadir}/patch_sets.csv' DELIMITER ',' CSV")
    ActiveRecord::Base.connection.execute("COPY messages FROM '#{datadir}/messages.csv' DELIMITER ',' CSV")
    ActiveRecord::Base.connection.execute("COPY patch_set_files FROM '#{datadir}/patch_set_files.csv' DELIMITER ',' CSV")
    ActiveRecord::Base.connection.execute("COPY comments FROM '#{datadir}/comments.csv' DELIMITER ',' CSV")
    ActiveRecord::Base.connection.execute("COPY developers FROM '#{datadir}/developers.csv' DELIMITER ',' CSV")
    ActiveRecord::Base.connection.execute("COPY participants FROM '#{datadir}/participants.csv' DELIMITER ',' CSV")
    ActiveRecord::Base.connection.execute("COPY contributors FROM '#{datadir}/contributors.csv' DELIMITER ',' CSV")
     
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
