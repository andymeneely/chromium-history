class RemoveCommiterEmailFromCommits < ActiveRecord::Migration
  def change
    remove_column :commits, :commiter_email, :string
  end
end
