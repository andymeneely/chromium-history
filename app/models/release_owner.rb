class ReleaseOwner < ActiveRecord::Base
  belongs_to :release, foreign_key: 'release', primary_key: 'name'
  belongs_to :filepath, foreign_key: 'filepath', primary_key: 'filepath'
  belongs_to :developer, foreign_key: 'dev_id', primary_key: 'id'
  belongs_to :firstOwnership,  foreign_key: 'dev_id', primary_key: 'dev_id'
  belongs_to :firstOwnership,  foreign_key: 'directory', primary_key: 'directory'

  def self.optimize
    connection.add_index :release_owners, :release
    connection.add_index :release_owners, :filepath
	connection.add_index :release_owners, :directory
    connection.add_index :release_owners, [:release,:filepath,:directory]
    connection.execute "CLUSTER release_owners USING index_release_owners_on_release_and_filepath_and_directory"
  end
end
