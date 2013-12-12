class AddCompositeKeyToPatchSet < ActiveRecord::Migration
  def change
    add_column :patch_sets, :composite_patch_set_id, :string
  end
end
