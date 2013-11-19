class WidenFilepathColumn < ActiveRecord::Migration
  def up
    remove_column :commit_files, :filepath
  end

  def down
    add_column :commit_files, :filepath, :string, :limit=>500
  end
end
