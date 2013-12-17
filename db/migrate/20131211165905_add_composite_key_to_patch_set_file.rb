class AddCompositeKeyToPatchSetFile < ActiveRecord::Migration
  def change
    add_column :patch_set_files, :composite_patch_set_id, :string
  end
end
