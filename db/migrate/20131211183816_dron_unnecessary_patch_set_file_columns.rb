class DronUnnecessaryPatchSetFileColumns < ActiveRecord::Migration
  def change
    remove_column :patch_set_files, :no_base_file
    remove_column :patch_set_files, :property_changes

  end
end
