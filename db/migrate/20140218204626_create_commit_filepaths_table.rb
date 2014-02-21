class CreateCommitFilepathsTable < ActiveRecord::Migration
  def change
    create_table :commit_filepaths do |t|
      t.string :commit_hash
      t.string :filepath
    end
  end
end
