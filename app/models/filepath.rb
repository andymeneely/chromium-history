class Filepath < ActiveRecord::Base

  has_many :commit_filepaths, primary_key: 'filepath', foreign_key: 'filepath'

	def self.on_optimize
    ActiveRecord::Base.connection.add_index :filepaths, :filepath, unique: true
  end

  #If a Filepath has ever been involved in a code review that inspected
  #a vulnerability, then this should return true.
  def vulnerable?
    cves.any?
  end

  def cves
    Filepath.joins(commit_filepaths: [commit: [code_review: :cvenums]]).where(filepath: filepath)
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

