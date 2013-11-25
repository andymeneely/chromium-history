class AddCommitHashToCommitFiles < ActiveRecord::Migration
  def change
    add_column :commit_files, :commit_hash, :string
  end
end
