class AddCodeReviewToMessage < ActiveRecord::Migration
  def change
    add_column :messages, :code_review_id, :integer
  end
end
