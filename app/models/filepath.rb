class Filepath < ActiveRecord::Base

  has_many :commit_filepaths, primary_key: 'filepath', foreign_key: 'filepath'
  has_many :release_owners, primary_key: 'filepath', foreign_key: 'filepath'

  def self.optimize
    connection.add_index :filepaths, :filepath, unique: true
    connection.execute 'CLUSTER filepaths USING index_filepaths_on_filepath'
  end

  def to_s
    filepath
  end

  # If a Filepath has ever been involved in a code review that inspected
  # a vulnerability fix, then this should return true.
  #
  # @param after - check for commit filepaths after a given date. Defaults to Jan 1, 1970
  def vulnerable?(dates=@@OPEN_DATES)
    cves(dates).any?
  end

  def cves(dates=@@OPEN_DATES)
    @@EXPLAINS[:cves] ||= Filepath.joins(commit_filepaths: [commit: [code_reviews: :cvenums]])\
      .where(filepath: filepath, \
             'commits.created_at' => dates).explain

    Filepath.joins(commit_filepaths: [commit: [code_reviews: :cvenums]])\
      .where(filepath: filepath, \
             'commits.created_at' => dates)
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
    @@EXPLAINS[:participants] ||= Filepath.participants\
      .select(:dev_id)\
      .where(filepath: filepath, \
             'code_reviews.created' => DateTime.new(1970,01,01)..before).explain

    Filepath.participants\
      .select(:dev_id)\
      .where(filepath: filepath, \
             'code_reviews.created' => DateTime.new(1970,01,01)..before)
      .uniq
  end
  
  #searches for bugs, with optional labels and years back
  @@OPEN_DATES = dates=DateTime.new(1970,01,01)..DateTime.new(2050,01,01)
  @@BUG_LABELS = %w(type-bug type-bug-regression type-bug-security type-defect type-regression)
  def bugs(dates=@@OPEN_DATES, labels=@@BUG_LABELS)
    
    @@EXPLAINS[:bugs] ||= Filepath.bugs\
      .select('bugs.bug_id')\
      .where(filepath: filepath, \
             :labels => {:label => labels},\
             'bugs.opened' => dates).explain

    Filepath.bugs\
      .select('bugs.bug_id')\
      .where(filepath: filepath, \
             :labels => {:label => labels},\
             'bugs.opened' => dates)
      .uniq
  end
  
  def code_reviews(before = DateTime.new(2050,01,01))
    Filepath.code_reviews\
      .where(filepath: filepath, \
             'code_reviews.created' => DateTime.new(1970,01,01)..before)
  end

  # The percentage of code reviews prior to this date where the code review
  # had at least one security_experienced partcipant
  def perc_security_exp_part(before = DateTime.new(2050,01,01))
    
    @@EXPLAINS[:perc_security_exp_part] ||=  Filepath.participants\
      .where('filepaths.filepath' => filepath,\
              'code_reviews.created' => DateTime.new(1970,01,01)..before)\
      .select('bool_or(security_experienced)')\
      .group('code_reviews.issue').explain

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

  # "Let's make it a distinct number of developers so two people working together doesn't keep stacking up." - issue description
  # If we want to make it a distinct number of developers, then we have to keep track of which developers is on a participants security_adjacency list. Meaning we will want to keep track of security-adjacencys not only on participants (for a specific code_review) but also within developer 
  # i.e we need to have an adjacencys table 
  def avg_security_adjacencys(before = DateTime.new(2050,01,01))
    denom = code_reviews(before).size
    return nil if denom == 0.0

    # num = Filepath.participants.where
  end

  def avg_security_exp_part(before = DateTime.new(2050,01,01))
    denom = code_reviews(before).size
    return nil if denom == 0.0

    num = Filepath.participants\
      .where('filepaths.filepath' => filepath,\
              'code_reviews.created' => DateTime.new(1970,01,01)..before,\
              'participants.security_experienced' => true)\
      .size

    return num/denom #total number of sec_exp parts per code review 
  end

  #Average number of sheirff hours per code review
  def avg_sheriff_hours(before = DateTime.new(2050,01,01))
    @@EXPLAINS[:code_reviews_before] ||= code_reviews(before).explain
    code_reviews(before).average(:total_sheriff_hours)
  end

  # Average number of non-participating reviewers
  def avg_non_participating_revs(before = DateTime.new(2050,01,01))
    code_reviews(before).average(:non_participating_revs)
  end

  # Average number of prior reviews with owner
  def avg_reviews_with_owner(before = DateTime.new(2050,01,01))
    code_reviews(before).average(:total_reviews_with_owner)
  end

  # Average number of prior reviews with owner
  def avg_owner_familiarity_gap(before = DateTime.new(2050,01,01))
    code_reviews(before).average(:owner_familiarity_gap)
  end

  # Percentage of overlooked patchsets
  def perc_overlooked_patchsets(before = DateTime.new(2050,01,01))
    denom = code_reviews.size
    return 0.0 if denom == 0

    num = 0.0
    CodeReview.joins(commit: [commit_filepaths: :filepath])\
      .where('filepaths.filepath' => filepath, \
             'code_reviews.created' => DateTime.new(1970,01,01)..before).each do |cr|
      num += 1.0 if cr.overlooked_patchset?
    end
    
    return num/denom
  end

  # Percentage of reviews with three or more reviewers
  def perc_three_more_reviewers(before = DateTime.new(2050,01,01))
    denom = code_reviews.size
    return 0.0 if denom == 0

    num = 0.0

    CodeReview.joins(:reviewers, commit: [commit_filepaths: :filepath])\
      .where('filepaths.filepath' => filepath,\
             'code_reviews.created' => DateTime.new(1970,01,01)..before)\
      .group('code_reviews.issue')\
      .select('code_reviews.issue', 'count(reviewers.dev_id) AS revs')\
      .each do |cr|
        num += 1.0 if cr['revs'] >= 3
      end
    return num/denom
  end

  # Percentage of fast reviews
  def perc_fast_reviews(before = DateTime.new(2050,01,01))
    #TODO Refactor code_reviews method to return CodeReview, not Filepath so we don't have to join here ourselves
    num = 0.0; denom = 0.0
    rs = CodeReview.joins(commit: [commit_filepaths: :filepath])\
      .where('filepaths.filepath' => filepath,\
             'code_reviews.created' => DateTime.new(1970,01,01)..before)
    rs.each do |cr|
      num += 1.0 if cr.loc_per_hour_exceeded? 200
      denom += 1.0
    end
    return 0.0 if denom == 0
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

  def self.bugs
    Filepath.joins(commit_filepaths: [commit: [commit_bugs: [bug: :labels]]])
  end

  @@EXPLAINS = {}
  def self.print_sql_explains
    @@EXPLAINS.each do |query, explain|
      puts "\n\n======= #{query} ======="
      puts explain
      puts "========================\n\n"
    end
  end

end
