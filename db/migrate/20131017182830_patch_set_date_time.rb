class PatchSetDateTime < ActiveRecord::Migration
  def change
    remove_column :patch_sets, :modified
    add_column :patch_sets, :modified, :datetime
  end
end
