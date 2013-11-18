class RemoveIndexCommitFilesOnCommitId < ActiveRecord::Migration
  def change
  	remove_index(:commit_files, :name => "index_commit_files_on_commit_id")
  end
end
