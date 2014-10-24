class Release < ActiveRecord::Base

  has_many :release_filepaths, primary_key: 'name', foreign_key: 'release'
  has_many :release_owners, primary_key: 'name', foreign_key: 'release'

  def self.optimize
    connection.add_index :releases, :name, unique: true
  end

end

