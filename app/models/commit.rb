class Commit < ActiveRecord::Base
  has_many :commit_files
  
  def self.on_optimize
  end
end
