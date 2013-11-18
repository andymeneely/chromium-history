class AddEmailToPatchSets < ActiveRecord::Migration
  def change
  	remove_column :patch_sets, :owner, :string
    add_column :patch_sets, :owner_email, :string
  end
end