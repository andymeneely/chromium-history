class CodeReview < ActiveRecord::Base
  has_many :patch_sets,  foreign_key: "code_review_id", primary_key: "issue"
  has_many :messages, foreign_key: "code_review_id", primary_key: "issue"
  has_many :reviewers, foreign_key: "issue", primary_key: "issue"
  has_many :participants, foreign_key: "issue", primary_key: "issue"
  has_many :contributors, foreign_key: "issue", primary_key: "issue"
  has_many :ccs, foreign_key: "issue", primary_key: "issue"

  has_one :commit, foreign_key: "code_review_id", primary_key: "issue"
  
  has_and_belongs_to_many :cvenums
  
  def self.on_optimize
    ActiveRecord::Base.connection.add_index :code_reviews, :issue, unique: true
  end

  def is_inspecting_vulnerability?
  	self.cvenums.empty?
  end

  # Adds up the number of add and remove lines from the associated patch set files.
  def total_churn
    CodeReview.joins(patch_sets: :patch_set_files).where(issue: issue).sum('num_added + num_removed')
  end

  # Add up the churn for the patch sets, and find the maximum
  def max_churn
    result = PatchSet.joins(:patch_set_files).where(code_review_id: issue).group('patch_sets.composite_patch_set_id').sum('num_added + num_removed').max
    result[1].to_i if !result.nil?
  end

  # An overlooked patchset is one that was created AFTER a reviwer approved the code review
  # It's a potential opportunity for un-reviewed code to be introduced.
  def self.overlooked_patchsets
    CodeReview.joins(:patch_sets, :messages)\
              .where('approval=true AND patch_sets.created > messages.date')
  end

  def overlooked_patchset?
    CodeReview.overlooked_patchsets.where(issue: issue).any?
  end

  def num_nonparticipating_reviewers
  	totalNonparticipating = 0;
  	reviewers = self.reviewers
  	for reviewer in reviewers 
  		if self.participants.where(["email=? and issue=?", reviewer.email, reviewer.issue]).exists?
  			totalNonparticipating += 1
  		end
  	end
  	return totalNonparticipating
  end

  def total_familiarity
    #FIXME self.reviewers.last isn't the right query for this. 
    puts familiarity(self.reviewers.last, self.reviewers.last)
  end

  def average_familiarity
    return "not done"
  end


  # Given two developers on this code review, return the number of prior code reviews they have both participated in together. 
  def familiarity(developer1, developer2)
    familiar = 0
    #FIXME This needs to be querying CodeReview joined with Participants. 
    beforeReviews = CodeReview.where("created < ?", self.created)  #get all the reviews that happened before the date of this review
    for review in beforeReviews
      for reviewer in review.reviewers
        # Don't print stuff to the console - it goes into stdout which gets mailed to Andy and pollutes the log with debug outputs.
        # puts reviewer.email 
      end
      if (review.reviewers.include?(developer1.email)) # && review.reviewers.include?(developer2))
        familiar += 1
        #puts familiar
      end
    end
    return familiar
  end

end
