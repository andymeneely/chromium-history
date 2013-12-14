class PatchSetFile < ActiveRecord::Base
  belongs_to :patch_set, primary_key: 'composite_patch_set_id'
  has_many :comments, foreign_key: 'composite_patch_set_file_id', primary_key: 'composite_patch_set_file_id'
  
  def self.on_optimize
    ActiveRecord::Base.connection.add_index :patch_set_files, :filepath
    ActiveRecord::Base.connection.add_index :patch_set_files, :patch_set_id
    ActiveRecord::Base.connection.add_index :patch_set_files, :composite_patch_set_id
    ActiveRecord::Base.connection.add_index :patch_set_files, :composite_patch_set_file_id, unique: true
  end
end
