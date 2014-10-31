class CommitFilepath < ActiveRecord::Base
	belongs_to :commit, foreign_key: 'commit_hash', primary_key: 'commit_hash'
	belongs_to :filepath, foreign_key: 'filepath', primary_key: 'filepath'


  def cve?
    Commit.joins(code_reviews: :cvenums).where(commit_hash: commit_hash).any?
  end

	def self.optimize
    connection.add_index :commit_filepaths, :commit_hash
    connection.add_index :commit_filepaths, :filepath
    connection.add_index :commit_filepaths, [:commit_hash, :filepath], unique: true
    connection.execute 'CLUSTER commit_filepaths USING index_commit_filepaths_on_filepath'
	end
end
