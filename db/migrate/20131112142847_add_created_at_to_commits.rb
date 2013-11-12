class AddCreatedAtToCommits < ActiveRecord::Migration
  def change
    add_column :commits, :created_at, :datetime
  end
end
