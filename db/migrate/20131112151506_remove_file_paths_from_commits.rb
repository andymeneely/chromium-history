class RemoveFilePathsFromCommits < ActiveRecord::Migration
  def change
    remove_column :commits, :filepaths, :string
  end
end
