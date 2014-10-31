class PatchSetFile < ActiveRecord::Base
  belongs_to :patch_set, primary_key: 'composite_patch_set_id'
  has_many :comments, foreign_key: 'composite_patch_set_file_id', primary_key: 'composite_patch_set_file_id'
  
  def self.optimize
    connection.add_index :patch_set_files, :filepath
    connection.add_index :patch_set_files, :composite_patch_set_id
    connection.add_index :patch_set_files, :composite_patch_set_file_id, unique: true
  end

  def churn
    num_added + num_removed
  end
end
