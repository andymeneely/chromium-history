class RemoveReviewersFromCommit < ActiveRecord::Migration
  def change
    remove_column :commits, :reviewers, :string
  end
end
