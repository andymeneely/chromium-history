class Commit < ActiveRecord::Base
	has_many :commit_files, foreign_key: "commit_hash", primary_key: "commit_hash"
  	
  has_many :commit_filepaths # For join table assoc
  has_many :filepaths, :through => :commit_filepaths # For join table assoc
  
  belongs_to :code_review, :class_name => 'CodeReview', foreign_key: 'code_review_id', primary_key: 'issue'

end
