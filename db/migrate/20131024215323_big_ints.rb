class BigInts < ActiveRecord::Migration
  def change
    remove_column :code_reviews, :issue
    add_column :code_reviews, :issue, :bigint
    
    remove_column :patch_sets, :patchset
    add_column :patch_sets, :patchset, :bigint
    end
end
