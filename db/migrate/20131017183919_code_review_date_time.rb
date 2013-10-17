class CodeReviewDateTime < ActiveRecord::Migration
  def change
    remove_column :code_reviews, :modified
    add_column :code_reviews, :modified, :datetime
  end
end
