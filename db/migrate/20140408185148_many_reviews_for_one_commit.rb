class ManyReviewsForOneCommit < ActiveRecord::Migration
  def change
    remove_column :commits, :code_review_id
    add_column :code_reviews, :commit_hash, :string
  end
end
