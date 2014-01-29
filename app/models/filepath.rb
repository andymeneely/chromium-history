class Filepath < ActiveRecord::Base
	has_many :commits_filepaths# For join table assoc
	has_many :commits, :through => :commits_filepaths# For join table assoc

	def self.on_optimize
  	end
end

