class AddContributors < ActiveRecord::Migration
  def change
    create_table :contributors do |t|
      t.string :email
      t.integer :issue, limit: 8
    end
  end
end
