class ReleaseOwner < ActiveRecord::Base
  belongs_to :release, foreign_key: 'release', primary_key: 'name'
  belongs_to :filepath, foreign_key: 'filepath', primary_key: 'filepath'
  belongs_to :developer, foreign_key: 'dev_id', primary_key: 'id'
  
  def self.optimize
    connection.add_index :release_owners, :filepath
	  #connection.add_index :release_owners, :directory
    #connection.add_index :release_owners, :dev_id
    connection.add_index :release_owners, [:directory, :dev_id]
    #connection.add_index :release_owners, [:release,:filepath,:directory]
    #connection.execute "CLUSTER release_owners USING index_release_owners_on_directory_and_dev_id"
  end
  
  def time_to_ownership
    first_ownership_date - first_dir_commit_date
  end
  
  def ownership_time_at_release
	release.date - first_ownership_date
  end
  
  def ownership_distance
    File.dirname(filepath.filepath).split(/\.\/|\//).count - directory.split(/\.\/|\//).count
  end
  
  def committed_filepaths_to_ownership
    self.directory = "" if self.directory.split(/\.\/|\//).count == 0
    return Commit.joins(:commit_filepaths).where(commit_hash:  CommitFilepath.where("filepath LIKE ?", "#{self.directory}%").pluck(:commit_hash), author_id: dev_id).where("created_at < ?", first_ownership_date).group(:filepath).count
  end
  
  def committed_filepaths_to_release
    self.directory = "" if self.directory.split(/\.\/|\//).count == 0
    return Commit.joins(:commit_filepaths).where(commit_hash:  CommitFilepath.where("filepath LIKE ?", "#{self.directory}%").pluck(:commit_hash), author_id: dev_id).where("created_at < ?", release.date).group(:filepath).count  
  end

end
