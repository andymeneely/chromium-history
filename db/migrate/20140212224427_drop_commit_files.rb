class DropCommitFiles < ActiveRecord::Migration
  def up
  	drop_table :commit_files
  end
end
