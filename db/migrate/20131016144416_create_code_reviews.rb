class CreateCodeReviews < ActiveRecord::Migration
  def change
    create_table :code_reviews do |t|
      t.text :description
      t.string :subject
      t.date :modified
      t.integer :issue

      t.timestamps
    end
  end
end
