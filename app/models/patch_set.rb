class PatchSet < ActiveRecord::Base
  belongs_to :code_review
  has_many :patch_set_files, foreign_key: "composite_patch_set_id", primary_key: "composite_patch_set_id"
  
  def files
    self.patch_set_files
  end 
  
  def churn
    patch_set_files.sum('num_added + num_removed')
  end

  def self.optimize
    connection.add_index :patch_sets, :code_review_id
    connection.add_index :patch_sets, :patchset
    connection.add_index :patch_sets, :owner_email
    connection.add_index :patch_sets, :composite_patch_set_id, unique: true
  end
end
