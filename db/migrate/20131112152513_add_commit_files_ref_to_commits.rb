class AddCommitFilesRefToCommits < ActiveRecord::Migration
  def change
    add_reference :commits, :commit_files, index: true
  end
end
