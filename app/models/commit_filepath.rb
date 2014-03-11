class CommitFilepath < ActiveRecord::Base
	belongs_to :commit, foreign_key: 'commit_hash', primary_key: 'commit_hash'
	belongs_to :filepaths, foreign_key: 'filepath', primary_key: 'filepath'


  def cve?
    commit.code_review.cvenums.any?
  end

	def self.on_optimize
	end
end
