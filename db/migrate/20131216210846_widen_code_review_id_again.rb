class WidenCodeReviewIdAgain < ActiveRecord::Migration
  def change
    remove_column :reviewers, :issue
    add_column :reviewers, :issue, :bigint

    #remove_column :cceds, :issue
    #add_column :cceds, :issue, :bigint
  end
end