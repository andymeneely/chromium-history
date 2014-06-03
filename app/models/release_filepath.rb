class ReleaseFilepath < ActiveRecord::Base

  belongs_to :release, primary_key: 'release', foreign_key: 'name'
  belongs_to :filepath, primary_key: 'filepath', foreign_key: 'filepath'

	def self.on_optimize
    ActiveRecord::Base.connection.add_index :release_filepaths, :filepath
    ActiveRecord::Base.connection.add_index :release_filepaths, :release
    ActiveRecord::Base.connection.add_index :release_filepaths, [:release, :filepath], unique: true
  end

end

