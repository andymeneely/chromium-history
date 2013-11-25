class Commit < ActiveRecord::Base
  has_many :commit_files, foreign_key: "commit_hash", primary_key: "commit_hash"
  
  def self.on_optimize
  end
end
