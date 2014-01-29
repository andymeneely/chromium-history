class RenameCodeReviewFieldOnCommit < ActiveRecord::Migration
  def change
    remove_column :commits, :code_review
    add_column :commits, :code_review_id, :bigint
  end
end
