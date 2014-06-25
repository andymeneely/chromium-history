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
      .where(filepath: filepath, \
             'commits.created_at' => after..DateTime.new(2050,01,01))
  end

  # Delegates to the static method with the where clause
  # Does not get the reviewers, returns Filepath object
  def reviewers(before=DateTime.new(2050,01,01))
    Filepath.reviewers\
      .select(:dev_id)\
      .where(filepath: filepath, \
             'code_reviews.created' => DateTime.new(1970,01,01)..before)\
      .uniq
  end

  def participants(before = DateTime.new(2050,01,01))
    Filepath.participants\
      .select(:dev_id)\
      .where(filepath: filepath, \
             'code_reviews.created' => DateTime.new(1970,01,01)..before)
      .uniq
  end

  def code_reviews(before = DateTime.new(2050,01,01))
    Filepath.code_reviews\
      .select(:issue)\
      .where(filepath: filepath, \
             'code_reviews.created' => DateTime.new(1970,01,01)..before)
  end

  # The percentage of code reviews prior to this date where the code review
  # had at least one security_experienced partcipant
  def perc_security_exp_part(before = DateTime.new(2050,01,01))
    rs = Filepath.participants\
      .where('filepaths.filepath' => filepath,\
              'code_reviews.created' => DateTime.new(1970,01,01)..before)\
      .select('bool_or(security_experienced)')\
      .group('code_reviews.issue')
    num = 0.0; denom = 0.0
    rs.each do |had_sec_exp_part|
      num += 1.0 if had_sec_exp_part['bool_or']
      denom += 1.0
    end
    return 0 if denom == 0
    return num/denom
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

  def self.code_reviews
    Filepath.joins(commit_filepaths: [commit: :code_reviews])
  end

end

