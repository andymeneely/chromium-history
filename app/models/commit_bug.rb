class CommitBug < ActiveRecord::Base
	belongs_to :commit, foreign_key: 'commit_hash', primary_key: 'commit_hash'
	belongs_to :bug, foreign_key: 'bug_id', primary_key: 'bug_id'

def self.optimize
    connection.add_index :commit_bugs, :commit_hash
    connection.add_index :commit_bugs, :bug_id
    connection.add_index :commit_bugs, [:commit_hash, :bug_id], unique: true
	end
end
