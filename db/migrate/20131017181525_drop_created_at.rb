class DropCreatedAt < ActiveRecord::Migration
  def change
    remove_column :patch_sets, :created_at
    remove_column :patch_sets, :updated_at
    
  end
end
