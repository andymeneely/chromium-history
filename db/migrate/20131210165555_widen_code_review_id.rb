class WidenCodeReviewId < ActiveRecord::Migration
  def change
    remove_column :messages, :code_review_id
    add_column :messages, :code_review_id, :bigint

    remove_column :patch_sets, :code_review_id
    add_column :patch_sets, :code_review_id, :bigint

    remove_column :patch_sets, :patchset
    add_column :patch_sets, :patchset, :bigint

    remove_column :patch_set_files, :patch_set_id
    add_column :patch_set_files, :patch_set_id, :bigint
    
    remove_column :comments, :patch_set_file_id
    add_column :comments, :patch_set_file_id, :bigint

  end
end
