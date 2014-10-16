class Commit < ActiveRecord::Base
  	
  has_many :commit_filepaths, foreign_key: 'commit_hash', primary_key: 'commit_hash' # For join table assoc
  
  has_many :commit_bugs, foreign_key: 'commit_hash', primary_key: 'commit_hash' # For join table assoc
 
  has_many :code_reviews, primary_key: "commit_hash", foreign_key: "commit_hash"
  
  def reviewers
    Commit.joins(code_reviews: :reviewers).where(commit_hash: commit_hash)
  end

  def self.optimize
    connection.add_index :commits, :commit_hash, unique: true
    connection.add_index :commits, :parent_commit_hash
    connection.add_index :commits, :author_email
  end

end
