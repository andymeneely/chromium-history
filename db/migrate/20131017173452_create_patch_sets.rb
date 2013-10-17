class CreatePatchSets < ActiveRecord::Migration
  def change
    create_table :patch_sets do |t|
      t.belongs_to :code_review
      t.integer :patchset
      t.datetime :modified
      t.datetime :created
      t.integer :num_comments
      t.text :message
      
      t.timestamps
    end
  end
end
