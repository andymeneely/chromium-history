class Filepath < ActiveRecord::Base
	has_many :commit_filepaths                     # For join table assoc
	has_many :commits, :through => :commit_filepaths # For join table assoc

  #If a Filepath has ever been involved in a code review that inspected
  #a vulnerability, then this should return true.
  def vulnerable?
    #self.cve?
  end

  def reviewers
    # Some stuff here
  end
end

