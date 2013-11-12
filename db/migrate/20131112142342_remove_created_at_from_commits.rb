class RemoveCreatedAtFromCommits < ActiveRecord::Migration
  def change
    remove_column :commits, :created_at, :date
  end
end
