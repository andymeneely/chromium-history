class AddSheriffs < ActiveRecord::Migration
  def change
  	create_table :sheriffs do |t|
      t.string :email
      t.datetime :start
      t.datetime :end
      t.string :title
    end
  end
end
