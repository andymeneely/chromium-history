class WidenFilepathAgain < ActiveRecord::Migration
  def change
    add_column :commit_files, :filepath, :string, :limit=>1000
  end
end
