class CreateCc < ActiveRecord::Migration
  def change
    create_table :ccs do |t|
      t.string :developer
      t.integer :issue, :limit => 8
    end
  end
end
