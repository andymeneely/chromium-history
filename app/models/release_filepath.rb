class ReleaseFilepath < ActiveRecord::Base

  belongs_to :release, primary_key: 'release', foreign_key: 'name'
  belongs_to :filepath, primary_key: 'filepath', foreign_key: 'thefilepath'
 
  self.primary_key = :id

  def self.on_optimize
    ActiveRecord::Base.connection.execute "ALTER TABLE release_filepaths ADD COLUMN id SERIAL"
    ActiveRecord::Base.connection.execute "ALTER TABLE release_filepaths ADD PRIMARY KEY (id)"
    ActiveRecord::Base.connection.add_index :release_filepaths, :thefilepath
    ActiveRecord::Base.connection.add_index :release_filepaths, :release
    ActiveRecord::Base.connection.add_index :release_filepaths, [:release, :thefilepath], unique: true
  end

  def self.source_code? filepath
    valid_extns = ['.h','.cc','.js','.cpp','.gyp','.py','.c','.make','.sh','.S''.scons','.sb','Makefile']
    valid_extns.include? File.extname(filepath)
  end
end
