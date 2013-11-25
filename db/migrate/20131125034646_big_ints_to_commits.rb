class BigIntsToCommits < ActiveRecord::Migration
  def change
    remove_column :commits, :code_review
    add_column :commits, :code_review, :bigint
  end
end
