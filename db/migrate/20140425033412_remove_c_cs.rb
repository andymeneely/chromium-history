class RemoveCCs < ActiveRecord::Migration
  def up
    drop_table :ccs
  end

  def down
    create_table :ccs do |t|
      t.string :email
			t.integer :issue, limit: 8
    end 
  end
end
