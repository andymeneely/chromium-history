class CreateReviewers < ActiveRecord::Migration
  def change
    create_table :reviewers do |t|
      t.string :developer
      t.integer :issue
    end
  end
end
