class AddCveToCodeReviews < ActiveRecord::Migration
  def change
    add_column :code_reviews, :cve, :string
  end
end
