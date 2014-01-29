class CreateJoinTableCommitFilepath < ActiveRecord::Migration
  def change
    create_join_table :commits, :filepaths do |t|
      t.index [:commit_id, :filepath_id]
      t.index [:filepath_id, :commit_id]
    end
  end
end
