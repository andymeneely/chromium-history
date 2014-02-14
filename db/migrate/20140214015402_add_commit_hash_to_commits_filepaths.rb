class AddCommitHashToCommitsFilepaths < ActiveRecord::Migration
  def change
    add_column :commits_filepaths, :commit_hash, :string
  end
end
