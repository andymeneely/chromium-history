class AddCodeReviewToCommit < ActiveRecord::Migration
  def change
    add_column :commits, :code_review, :integer
  end
end
