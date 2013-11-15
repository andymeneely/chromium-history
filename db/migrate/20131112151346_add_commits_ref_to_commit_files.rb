class AddCommitsRefToCommitFiles < ActiveRecord::Migration
  def change
    add_reference :commit_files, :commit
  end
end
