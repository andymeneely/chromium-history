class AddCompositePatchSetFileId < ActiveRecord::Migration
  def change
    add_column :patch_set_files, :composite_patch_set_file_id, :string, :limit=>1000
    add_column :comments, :composite_patch_set_file_id, :string, :limit=>1000
  end
end
