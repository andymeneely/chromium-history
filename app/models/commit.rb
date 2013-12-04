class Commit < ActiveRecord::Base
  has_many :commit_files, foreign_key: "commit_hash", primary_key: "commit_hash"
  
  def self.on_optimize
    ActiveRecord::Base.connection.add_index :commits, :commit_hash, unique: true
    ActiveRecord::Base.connection.add_index :commits, :parent_commit_hash
    ActiveRecord::Base.connection.add_index :commits, :author_email

  end
end
