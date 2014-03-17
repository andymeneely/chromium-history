class AddParticipants < ActiveRecord::Migration
  def change
    create_table :participants do |t|
      t.string :email
      t.integer :issue, limit: 8
    end
  end
end
