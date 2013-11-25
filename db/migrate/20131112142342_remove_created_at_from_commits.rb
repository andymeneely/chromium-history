class RemoveCreatedAtFromCommits < ActiveRecord::Migration
  def change
    remove_column :commits,:created_at,:date if column_exists? :commits,:created_at
  end
end
