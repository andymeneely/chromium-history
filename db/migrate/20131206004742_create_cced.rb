class CreateCced < ActiveRecord::Migration
  def change
    create_table :cceds do |t|
      t.string :developer
      t.integer :issue
    end
  end
end
