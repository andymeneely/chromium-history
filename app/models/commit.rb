class Commit < ActiveRecord::Base
  has_many :commit_files
  
  def self.on_optimize #create indexes on what keys?
  end

end
