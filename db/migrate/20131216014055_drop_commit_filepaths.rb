class DropCommitFilepaths < ActiveRecord::Migration
  def up
  	drop_table :commit_filepaths
  end
end
