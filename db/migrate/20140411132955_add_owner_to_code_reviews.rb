class AddOwnerToCodeReviews < ActiveRecord::Migration
  def change
    add_column :code_reviews, :owner_email, :string
  end
end
