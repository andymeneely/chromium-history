class CommitFilepath < ActiveRecord::Base
	belongs_to :commits, foreign_key: 'commit_hash', primary_key: 'commit_hash'
	belongs_to :filepaths, foreign_key: 'filepath', primary_key: 'filepath'


	def self.on_optimize
	end
end
