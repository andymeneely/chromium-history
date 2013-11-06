class RemoveCommiterEmailFromCommits < ActiveRecord::Migration
  def change
    remove_column :commits, :committer_email, :string
  end
end
