class ReleaseFilepath < ActiveRecord::Base

  belongs_to :release, primary_key: 'release', foreign_key: 'name'
  belongs_to :filepath, primary_key: 'filepath', foreign_key: 'thefilepath'
 
  self.primary_key = :id

  def self.optimize
    connection.execute "ALTER TABLE release_filepaths ADD COLUMN id SERIAL"
    connection.execute "ALTER TABLE release_filepaths ADD PRIMARY KEY (id)"
    connection.add_index :release_filepaths, :thefilepath
    connection.add_index :release_filepaths, :release
    connection.add_index :release_filepaths, [:release, :thefilepath], unique: true
  end

  def self.source_code? filepath
    valid_extns = ['.h','.cc','.js','.cpp','.gyp','.py','.c','.make','.sh','.S''.scons','.sb','Makefile']
    valid_extns.each { |extn| if filepath.ends_with?(extn) then return true end }
    return false
  end
end
