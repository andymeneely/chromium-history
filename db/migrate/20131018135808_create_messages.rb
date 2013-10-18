class CreateMessages < ActiveRecord::Migration
  def change
    create_table :messages do |t|
      t.string :sender
      t.text :text
      t.boolean :approval
      t.boolean :disapproval
      t.datetime :date
    end
  end
end
