class DropAllCommitFilepathTables < ActiveRecord::Migration
  def change
    drop_table :commit_files
    drop_table :commit_filepaths
    drop_table :commits_filepaths
  end
end
