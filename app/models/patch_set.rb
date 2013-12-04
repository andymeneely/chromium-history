class PatchSet < ActiveRecord::Base
  belongs_to :code_review
  has_many :patch_set_files
  
  def files
    self.patch_set_files
  end 
  
  def self.on_optimize
    ActiveRecord::Base.connection.add_index :patch_sets, :code_review_id
    ActiveRecord::Base.connection.add_index :patch_sets, :patchset
    ActiveRecord::Base.connection.add_index :patch_sets, :owner_email
  end
end
