class ReleaseOwner < ActiveRecord::Base
  belongs_to :release, foreign_key: 'release', primary_key: 'name'
  belongs_to :filepath, foreign_key: 'filepath', primary_key: 'filepath'
  belongs_to :developer, foreign_key: 'dev_id', primary_key: 'id'
  
  def self.optimize
    connection.add_index :release_owners, :release
    connection.add_index :release_owners, :filepath
	  connection.add_index :release_owners, :directory
    connection.add_index :release_owners, :dev_id
    connection.add_index :release_owners, [:directory, :dev_id]
    connection.add_index :release_owners, [:release,:filepath,:directory]
    connection.execute "CLUSTER release_owners USING index_release_owners_on_directory_and_dev_id"
  end
end
