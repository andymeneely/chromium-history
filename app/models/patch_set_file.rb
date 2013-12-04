class PatchSetFile < ActiveRecord::Base
  belongs_to :patch_set
  has_many :comments
  
  def self.on_optimize
    ActiveRecord::Base.connection.add_index :patch_set_files, :filepath
    ActiveRecord::Base.connection.add_index :patch_set_files, :patch_set_id
  end
end
