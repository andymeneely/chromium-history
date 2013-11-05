class RemoveCommiterNameFromCommits < ActiveRecord::Migration
  def change
    remove_column :commits, :committer_name, :string
  end
end
