class RemoveIndexCommitFilesOnCommitIdFromCommitFiles < ActiveRecord::Migration
  def change
    remove_column :commit_files,:index_commit_files_on_commit_id,:integer if column_exists? :commit_files,:index_commit_files_on_commit_id
  end
end
