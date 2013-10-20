class AddIndices < ActiveRecord::Migration
  def change
    add_index :code_reviews, :issue, unique: true
    add_index :patch_set_files, [:num_added, :num_removed]
  end
end
