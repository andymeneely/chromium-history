class ChangeDeveloperToEmail < ActiveRecord::Migration
  def change
    remove_column :ccs,:developer
    remove_column :reviewers,:developer
    add_column :ccs,:email, :string
    add_column :reviewers,:email,:string
  end
end
