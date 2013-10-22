class PatchSet < ActiveRecord::Base
  belongs_to :code_review
  has_many :patch_set_files
  
  def files
    self.patch_set_files
  end 
  
  def self.on_optimize
  end
end
