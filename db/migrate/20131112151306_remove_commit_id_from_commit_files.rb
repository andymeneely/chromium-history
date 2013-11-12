class RemoveCommitIdFromCommitFiles < ActiveRecord::Migration
  def change
    remove_column :commit_files, :commit_id, :integer
  end
end
