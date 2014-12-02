class FirstOwnership < ActiveRecord::Base
  belongs_to :releaseowner, foreign_key: 'owner_email', primary_key: 'owner_email'
  belongs_to :releaseowner, foreign_key: 'dev_id', primary_key: 'dev_id'
  belongs_to :filepath, foreign_key: 'filepath', primary_key: 'filepath'

  def self.optimize
	connection.add_index :first_ownerships, :filepath
    connection.add_index :first_ownerships, :owner_email
    connection.add_index :first_ownerships, [:filepath,:owner_email]
    connection.execute "CLUSTER first_ownerships USING index_first_ownerships_on_filepath_and_owner_email"
  end
end
