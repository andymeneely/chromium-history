class CreateComments < ActiveRecord::Migration
  def change
    create_table :comments do |t|
      t.string :author_email
      t.text :text
      t.boolean :draft
      t.integer :lineno
      t.datetime :date
      t.boolean :left
      t.belongs_to :patch_set_file
    end
  end
end
