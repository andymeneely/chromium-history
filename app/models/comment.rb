class Comment < ActiveRecord::Base
  belongs_to :patch_set_file
  
  def self.on_optimize
  
  end
end
