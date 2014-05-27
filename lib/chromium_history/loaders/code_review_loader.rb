require 'set'
require 'csv'

class CodeReviewLoader
  
  def copy_parsed_tables 
    #ActiveRecord::Base.connection.execute("COPY cvenums FROM '#{Rails.configuration.datadir}/cvenums.csv' DELIMITER ',' CSV")

    datadir = File.expand_path(Rails.configuration.datadir + "/tmp")
    ActiveRecord::Base.connection.execute("COPY code_reviews FROM '#{datadir}/code_reviews.csv' DELIMITER ',' CSV")
    ActiveRecord::Base.connection.execute("ALTER TABLE code_reviews ADD COLUMN owner_id integer")
    ActiveRecord::Base.connection.execute("ALTER TABLE code_reviews ADD COLUMN commit_hash varchar")

    ActiveRecord::Base.connection.execute("COPY reviewers FROM '#{datadir}/reviewers.csv' DELIMITER ',' CSV")
    ActiveRecord::Base.connection.execute("ALTER TABLE reviewers ADD COLUMN dev_id integer")

    ActiveRecord::Base.connection.execute("COPY patch_sets FROM '#{datadir}/patch_sets.csv' DELIMITER ',' CSV")
    
    ActiveRecord::Base.connection.execute("COPY messages FROM '#{datadir}/messages.csv' DELIMITER ',' CSV")
    ActiveRecord::Base.connection.execute("ALTER TABLE messages ADD COLUMN sender_id integer")
    
    ActiveRecord::Base.connection.execute("COPY patch_set_files FROM '#{datadir}/patch_set_files.csv' DELIMITER ',' CSV")
    
    ActiveRecord::Base.connection.execute("COPY comments FROM '#{datadir}/comments.csv' DELIMITER ',' CSV")
    ActiveRecord::Base.connection.execute("ALTER TABLE comments ADD COLUMN author_id integer")
  end

  def load_developers
    developers = {}
    load_many developers, "SELECT DISTINCT owner_email AS email FROM code_reviews", 'reviewers', 'dev_id', 'email'
    load_many developers, "SELECT DISTINCT email from reviewers", 'code_reviews', 'owner_id', 'owner_email'
    load_many developers, "SELECT DISTINCT sender AS email from messages", 'messages', 'sender_id', 'sender'
    load_many developers, "SELECT DISTINCT author_email AS email from comments", 'comments', 'author_id', 'author_email'
  end

  def load_many developers, query, update_table, dev_id_column, email_column
    raws = ActiveRecord::Base.connection.execute(query)
    values = []
    raws.each do |raw|
      email, valid = Developer.sanitize_validate_email raw['email']
      next unless valid 
      unless developers.include?(email)
        developer = Developer.new
        developer.email = email
        developer.save
        developers[email] = dev_id = developer.id
      else 
        dev_id = developers[email]
      end
      values << "(#{dev_id}, '#{raw['email']}')"
    end
    update = "UPDATE #{update_table} AS m SET
              #{dev_id_column} = c.id
              FROM (values #{values.join(', ')}) AS c (id, address) 
              WHERE #{email_column} = c.address;"
    ActiveRecord::Base.connection.execute(update)
  end

  def add_primary_keys
    ActiveRecord::Base.connection.execute "ALTER TABLE messages ADD COLUMN id SERIAL; ALTER TABLE messages ADD PRIMARY KEY (id);"
    ActiveRecord::Base.connection.execute "ALTER TABLE comments ADD COLUMN id SERIAL; ALTER TABLE comments ADD PRIMARY KEY (id);"
    ActiveRecord::Base.connection.execute "ALTER TABLE patch_sets ADD COLUMN id SERIAL; ALTER TABLE patch_sets ADD PRIMARY KEY (id);"
    ActiveRecord::Base.connection.execute "ALTER TABLE patch_set_files ADD COLUMN id SERIAL; ALTER TABLE patch_set_files ADD PRIMARY KEY (id);"
    ActiveRecord::Base.connection.execute "ALTER TABLE reviewers ADD COLUMN id SERIAL; ALTER TABLE reviewers ADD PRIMARY KEY (id);"
    ActiveRecord::Base.connection.execute("CREATE INDEX ON code_reviews USING hash (issue)")
  end
end
