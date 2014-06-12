class Filepath < ActiveRecord::Base

  has_many :commit_filepaths, primary_key: 'filepath', foreign_key: 'filepath'

	def self.on_optimize
    ActiveRecord::Base.connection.add_index :filepaths, :filepath, unique: true
  end

  # If a Filepath has ever been involved in a code review that inspected
  # a vulnerability fix, then this should return true.
  #
  # @param after - check for commit filepaths after a given date. Defaults to Jan 1, 1970
  def vulnerable?(after=DateTime.new(1970,01,01))
    cves(after).any?
  end

  def cves(after=DateTime.new(1970,01,01))
    Filepath.joins(commit_filepaths: [commit: [code_reviews: :cvenums]])\
      .where(filepath: filepath, 'commits.created_at' => after..DateTime.now)
  end

  # Delegates to the static method with the where clause
  # Does not get the reviewers, returns Filepath object
  def reviewers
    Filepath.reviewers\
      .select(:dev_id)\
      .where(filepath: filepath)\
      .uniq
  end
  
  # All of the Reviewers for all filepaths joined together
  #   Note: this uses multi-level nested associations
  def self.reviewers
    Filepath.joins(commit_filepaths: [commit: [code_reviews: :reviewers]])
  end


  # All of the participants joined
  # Returns participants relation
  def self.participants
    Filepath.joins(commit_filepaths: [commit: [code_reviews: [participants: :developer]]])
  end

  # All of the contributors joined
  def self.contributors
    Filepath.joins(commit_filepaths: [commit: [code_reviews: [contributors: :developer]]])
  end

  #Returns participants objects
  def participants_on_filepath
    Participant.joins("INNER JOIN code_reviews ON participants.issue=code_reviews.issue INNER JOIN commits ON code_reviews.commit_hash=commits.commit_hash INNER JOIN commit_filepaths ON commit_filepaths.commit_hash=commits.commit_hash INNER JOIN filepaths ON filepaths.filepath=commit_filepaths.filepath WHERE filepaths.filepath='#{self.filepath}'")
  end

end

