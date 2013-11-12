class Commit < ActiveRecord::Base
  has_one :commit_files
  
  def self.on_optimize
  end
end
