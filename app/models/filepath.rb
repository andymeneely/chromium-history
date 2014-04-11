class Filepath < ActiveRecord::Base

  has_many :commit_filepaths, primary_key: 'filepath', foreign_key: 'filepath'

	def self.on_optimize
    ActiveRecord::Base.connection.add_index :filepaths, :filepath, unique: true
  end

  #If a Filepath has ever been involved in a code review that inspected
  #a vulnerability, then this should return true.
  def vulnerable?
    cves.any?
  end

  def cves
    Filepath.joins(commit_filepaths: [commit: [code_review: :cvenums]]).where(filepath: filepath)
  end

  # Delegates to the static method with the where clause
  # Does not get the reviewers, returns Filepath object
  def reviewers
    Filepath.reviewers.where(filepath: filepath).uniq
  end
  
  # All of the Reviewers for this given filepath at any time
  #   Note: this uses multi-level nested associations
  def self.reviewers
    Filepath.joins(commit_filepaths: [commit: [code_review: :reviewers]])
  end

  # Get the number of developers
  # who have reviewed vulnerablities up until 
  # the param date who have also inspected
  # this Filepath. Does not work b/c self.reviewers
  # returns Filepath, not reviewers
  #
  # @param- date Time object or string. Str format: "DD-MM-YYYY HH:MM:SS"
  # @return - number of vulnerability developers
  def num_vulnerable_devs(date=Time.now)

    #if date is a string then convert to Time object
    if date.class == String then date = Time.new(date) end

    #Get all the reviewers associated w/
    #this Filepath
    reviewers = self.reviewers
    dev_vul_count = 0
    reviewers.each do |reviewer| 
      
      #Get the developer who is this reviewer
      dev = reviewer.developer

      #if the dev inspected vulnerable reveiews then this is a vulnerability dev
      if dev.num_vulnerable_inspects(date) > 0 then dev_vul_count+=1 end

    end#loop

    return dev_vul_count

  end#num_of_vulnerable_devs

end

