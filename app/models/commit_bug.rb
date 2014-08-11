class CommitBug < ActiveRecord::Base
	belongs_to :commit, foreign_key: 'commit_hash', primary_key: 'commit_hash'
	belongs_to :bug, foreign_key: 'bug_id', primary_key: 'bug_id'

def self.on_optimize
    ActiveRecord::Base.connection.add_index :commit_bugs, :commit_hash
    ActiveRecord::Base.connection.add_index :commit_bugs, :bug_id
    ActiveRecord::Base.connection.add_index :commit_bugs, [:commit_hash, :bug_id], unique: true
	end
end
