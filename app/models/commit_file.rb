class CommitFile < ActiveRecord::Base
  belongs_to :commit, foreign_key: "commit_hash", primary_key: "commit_hash"

  def self.on_optimize
  end
 

end