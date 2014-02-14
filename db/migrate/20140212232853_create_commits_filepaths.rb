class CreateCommitsFilepaths < ActiveRecord::Migration
  def down
    create_table :commits_filepaths do |t|
    	t.string :commit_hash
    	t.integer :filepath_id 
    end
  end
end
