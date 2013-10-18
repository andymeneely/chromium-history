class CreatePatchSetFiles < ActiveRecord::Migration
  def change
    create_table :patch_set_files do |t|
      t.string :filepath
      t.string :status
      t.integer :num_chunks
      t.boolean :no_base_file
      t.boolean :property_changes
      t.integer :num_added
      t.integer :num_removed
      t.boolean :is_binary
      t.belongs_to :patch_set
    end
  end
end
