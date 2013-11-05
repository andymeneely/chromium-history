class RemoveIndexFromCommitFiles < ActiveRecord::Migration
  def change
    remove_index :commit_files, :commit_id
  end
end
