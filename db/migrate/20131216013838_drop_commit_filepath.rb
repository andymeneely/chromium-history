class DropCommitFilepath < ActiveRecord::Migration
  def up
  	drop_table :commit_filepath
  end
end
