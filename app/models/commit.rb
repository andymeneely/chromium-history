class Commit < ActiveRecord::Base
  	
  has_many :commit_filepaths, foreign_key: 'commit_hash', primary_key: 'commit_hash' # For join table assoc
  
  belongs_to :code_review, primary_key: "issue", foreign_key: "code_review_id"

  def reviewers
    self.code_review.reviewers
  end

  def self.on_optimize
    ActiveRecord::Base.connection.add_index :commits, :commit_hash, unique: true
    ActiveRecord::Base.connection.add_index :commits, :parent_commit_hash
    ActiveRecord::Base.connection.add_index :commits, :author_email
  end

end
