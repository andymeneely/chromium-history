class Filepath < ActiveRecord::Base

  has_many :commit_filepaths, primary_key: 'filepath', foreign_key: 'filepath'

	def self.on_optimize
    ActiveRecord::Base.connection.add_index :filepaths, :path, unique: true
  end

  #If a Filepath has ever been involved in a code review that inspected
  #a vulnerability, then this should return true.
  def vulnerable?
    path = self.path 
    commit_filepath = CommitFilepath.find_by filepath: path 
    commit_filepath.cve?
    




  end

  # Delegates to the static method with the where clause
  def reviewers
    Filepath.reviewers.where(filepath: filepath).uniq
  end
  
  # All of the Reviewers for this given filepath at any time
  #   Note: this uses multi-level nested associations
  def self.reviewers
    Filepath.joins(commit_filepaths: [commit: [code_review: :reviewers]])
  end

end

