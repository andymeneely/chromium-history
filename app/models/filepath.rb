class Filepath < ActiveRecord::Base
	has_many :commits_filepaths# For join table assoc
	has_many :commits, :through => :commits_filepaths# For join table assoc

	def self.on_optimize
  	end

  	#If a Filepath has ever been involved in a code review that inspected 
  	#a vulnerability, then this should return true.
  	def vulnerable?
  		#self.cve?
 	end
end

