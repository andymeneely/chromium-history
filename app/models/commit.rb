class Commit < ActiveRecord::Base
  	
  has_many :commit_filepaths, foreign_key: 'commit_hash', primary_key: 'commit_hash' # For join table assoc
  has_many :commit_bugs, foreign_key: 'commit_hash', primary_key: 'commit_hash' # For join table assoc
  has_many :code_reviews, primary_key: "commit_hash", foreign_key: "commit_hash"
  belongs_to :developer, primary_key: "id", foreign_key: "author_id"
  has_and_belongs_to_many :technical_words

  def reviewers
    Commit.joins(code_reviews: :reviewers).where(commit_hash: commit_hash)
  end

  def self.optimize
    connection.add_index :commits, :commit_hash, unique: true
    connection.add_index :commits, :parent_commit_hash
    connection.add_index :commits, :author_email
    connection.add_index :commits, :created_at
    PsqlUtil.add_fulltext_search_index 'commits', 'message'
    connection.execute 'CLUSTER commits USING index_commits_on_created_at'
  end

end
