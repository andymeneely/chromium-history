class CreateCommitFiles < ActiveRecord::Migration
  def change
    create_table :commit_files do |t|
      t.belongs_to :commit, index: true
      t.string :filepath
    end
  end
end
