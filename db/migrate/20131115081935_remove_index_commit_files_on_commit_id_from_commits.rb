class RemoveIndexCommitFilesOnCommitIdFromCommits < ActiveRecord::Migration
  def change
    remove_column :commits, :index_commit_files_on_commit_id, :integer
  end
end
