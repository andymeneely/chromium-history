class AddOwnerToPatchSet < ActiveRecord::Migration
  def change
    add_column :patch_sets, :owner, :string
  end
end
