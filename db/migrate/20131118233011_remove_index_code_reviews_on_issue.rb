class RemoveIndexCodeReviewsOnIssue < ActiveRecord::Migration
  def change
    remove_index(:code_reviews, :name => "index_code_reviews_on_issue")
  end
end
