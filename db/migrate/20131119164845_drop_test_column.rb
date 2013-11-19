class DropTestColumn < ActiveRecord::Migration
  def change
    remove_column :commits, :test
  end
end
