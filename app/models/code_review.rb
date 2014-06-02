class CodeReview < ActiveRecord::Base
  has_many :patch_sets,  foreign_key: "code_review_id", primary_key: "issue"
  has_many :messages, foreign_key: "code_review_id", primary_key: "issue"
  has_many :reviewers, foreign_key: "issue", primary_key: "issue"
  has_many :participants, foreign_key: "issue", primary_key: "issue"
  has_many :contributors, foreign_key: "issue", primary_key: "issue"

  belongs_to :commit, foreign_key: "commit_hash", primary_key: "commit_hash"
  
  has_and_belongs_to_many :cvenums
  
  self.primary_key = :issue
  
  def self.on_optimize
    # ActiveRecord::Base.connection.add_index :code_reviews, :issue, unique: true
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
  		if self.participants.where(["dev_id=? and issue=?", reviewer.dev_id, reviewer.issue]).exists?
  			totalNonparticipating += 1
  		end
  	end
  	return totalNonparticipating
  end

  #returns the familiarity of all the reviews added up
  def total_familiarity
    total = 0 # initially the number is zero total
    participants = self.participants
    for participant in participants
      total += participant.reviews_with_owner
    end
    return total
  end

  def average_familiarity
    total = 0 # initially the number is zero total
    participants = self.participants
    for participant in participants
      total += participant.reviews_with_owner
    end
    average = total / participants.count
    return average
  end

  #
  # Security Experienced Participants
  # Return participants who participated
  # in a code review of a prior security fixing
  # code review. Ensure that the prior code reviews
  # came before this one
  #
  # @return - Array of Participants 
  def security_experienced_parts

    experienced_participants = Array.new
    start_date = self.created

    #get all participants for this code review
    participants = self.participants

    participants.each do |p|

      #get the developer 
      dev = p.developer

      #they inspected a code review with a CVE before this code review
      if dev.num_vulnerable_inspects(start_date) > 0 

        #add participant to array
        experienced_participants.push(p)

      end#if

    end#loop

    return experienced_participants

  end#num_security_experienced_parts

  #
  # Determine whether or not total 
  # churn for all patchsets exceeds
  # @param Lines of Code per hour
  #
  # @param - lines of code
  # @return - boolean 
  def loc_per_hour_exceeded?(lines=200)

    #get total churn for all patchsets
    total_churn = self.total_churn

    #date codereview created
    created = self.created

    #get all messages for this codereview
    messages = self.messages.order(date: :asc)

    #date of approval message
    date_approval_mess = nil

    messages.each do |mess|

      #FIXME Approvals need to have the flag, not the message!!!
      #find 1st message w/ approval message (LGTM)
      if mess.text.match('LGTM') then
        date_approval_mess = mess.date
        break
      end#if

    end#loop

    #no approval message - RETURN FALSE
    if date_approval_mess.nil? then return false end

    total_time = date_approval_mess - created

    #get total hours
    total_time_hours = (total_time / 60) / 60

    #divide total amount of churn by total hours that passed
    loc_per_hour = (total_churn / total_time_hours)

    if loc_per_hour > lines then return true else return false end

  end#loc_per_hour_exceeded?

end#class
