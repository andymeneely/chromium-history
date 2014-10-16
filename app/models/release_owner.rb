class ReleaseOwner < ActiveRecord::Base
  belongs_to :release, foreign_key: 'release', primary_key: 'name'
  belongs_to :filepath, foreign_key: 'filepath', primary_key: 'filepath'
  belongs_to :developer, foreign_key: 'owner_email', primary_key: 'email'

  def self.optimize
    connection.add_index :release_owners, :release
    connection.add_index :release_owners, :filepath
    connection.add_index :release_owners, [:release,:filepath]
    connection.execute "CLUSTER release_owners USING index_release_owners_on_release_and_filepath"
  end
end
