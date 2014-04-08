class CommitFilepath < ActiveRecord::Base
	belongs_to :commit, foreign_key: 'commit_hash', primary_key: 'commit_hash'
	belongs_to :filepaths, foreign_key: 'filepath', primary_key: 'filepath'


  def cve?
    Commit.joins(code_reviews: :cvenums).where(commit_hash: commit_hash).any?
  end

	def self.on_optimize
    ActiveRecord::Base.connection.add_index :commit_filepaths, :commit_hash
    ActiveRecord::Base.connection.add_index :commit_filepaths, :filepath
    ActiveRecord::Base.connection.add_index :commit_filepaths, [:commit_hash, :filepath], unique: true
	end
end
