class FirstOwnership < ActiveRecord::Base
  has_many :releaseOwners, primary_key: 'dev_id', foreign_key: 'dev_id' 
  has_many :releaseOwners, primary_key: 'directory', foreign_key: 'directory' 

  def self.optimize
	connection.add_index :first_ownerships, :directory
    connection.add_index :first_ownerships, :owner_email
    connection.add_index :first_ownerships, [:directory,:owner_email]
    connection.execute "CLUSTER first_ownerships USING index_first_ownerships_on_directory_and_owner_email"
  end
end
