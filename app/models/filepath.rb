class Filepath < ActiveRecord::Base

  has_many :commit_filepaths, primary_key: 'filepath', foreign_key: 'filepath'

	def self.on_optimize
    ActiveRecord::Base.connection.add_index :filepaths, :filepath, unique: true
  end

  #If a Filepath has ever been involved in a code review that inspected
  #a vulnerability, then this should return true.
  def vulnerable?
    #filepath = self.Filepath;
    #commit = filepath.commit;
    #codeRev = commit.code_review;
    #codeRev.is_inspecting_vulnerability?
  end

  def reviewers
    # Some stuff here
  end
end

