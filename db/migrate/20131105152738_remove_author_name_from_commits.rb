class RemoveAuthorNameFromCommits < ActiveRecord::Migration
  def change
    remove_column :commits, :author_name, :string
  end
end
