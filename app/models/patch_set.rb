class PatchSet < ActiveRecord::Base
  belongs_to :code_review
  has_many :patch_set_files, foreign_key: "composite_patch_set_id", primary_key: "composite_patch_set_id"
  
  def files
    self.patch_set_files
  end 

end
