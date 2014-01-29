class CreateFilepaths < ActiveRecord::Migration
  def change
    create_table :filepaths do |t|
      t.string :path

      t.timestamps
    end
  end
end
