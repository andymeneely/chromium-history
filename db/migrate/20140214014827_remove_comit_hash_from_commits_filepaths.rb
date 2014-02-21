class RemoveComitHashFromCommitsFilepaths < ActiveRecord::Migration
  def change
    remove_column :commits_filepaths, :commit_hash, :integer
  end
end
