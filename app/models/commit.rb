class Commit < ActiveRecord::Base
  	
  has_many :filepaths, :through => :commits_filepaths, foreign_key: 'commit_hash', primary_key: 'commit_hash' # For join table assoc
  
  belongs_to :code_review, :class_name => 'CodeReview', foreign_key: 'code_review_id', primary_key: 'issue'

  def self.on_optimize
    ActiveRecord::Base.connection.add_index :commits, :commit_hash, unique: true
    ActiveRecord::Base.connection.add_index :commits, :parent_commit_hash
    ActiveRecord::Base.connection.add_index :commits, :author_email
  end

end
