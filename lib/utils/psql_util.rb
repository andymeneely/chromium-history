require 'csv'

# Common Postgres specific logic
class PsqlUtil

  # Adds an id column and creates an auto-incremeted primary index on the column
  def self.add_auto_increment_key table_name, key_name='id'
    PsqlUtil.execute "ALTER TABLE #{table_name} ADD COLUMN #{key_name} SERIAL" 
    PsqlUtil.add_primary_key table_name, key_name
  end

  def self.add_primary_key table_name, key_name='id'
    PsqlUtil.execute "ALTER TABLE #{table_name} ADD PRIMARY KEY (#{key_name})"
  end

  def self.add_index table_name, column_name, type='btree'
    PsqlUtil.execute "CREATE INDEX ON #{table_name} USING #{type} (#{column_name})"
  end

  # Copy to table from csv
  # TODO: add multiple format support
  def self.copy_from_file table_name, file_path
    PsqlUtil.execute "COPY #{table_name} FROM '#{file_path}' DELIMITER ',' CSV ENCODING 'utf-8'"
  end

  def self.copy_to_file query, file_path, format='CSV'
    PsqlUtil.execute "COPY(#{query}) TO '#{file_path}' WITH (FORMAT #{format})"
  end

  # Create GIN index on textual field in table
  def self.add_fulltext_search_index table_name, searchable_field
    sql = <<-eos
      CREATE INDEX #{table_name}_search 
      ON #{table_name} 
      USING gin(to_tsvector('english', #{searchable_field}));
    eos
    PsqlUtil.execute sql
  end

  # iterate through block to fill csv table file
  def self.create_upload_file file_path, &block
    table = CSV.open "#{file_path}", 'w+'
    block.call table
    table.fsync
  end

  def self.execute_file sql_file
    ActiveRecord::Base.connection.execute IO.read(sql_file)
  end

  # Convenience function
  def self.execute sql
    ActiveRecord::Base.connection.execute sql
  end
end