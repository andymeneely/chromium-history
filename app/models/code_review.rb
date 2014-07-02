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
    ActiveRecord::Base.connection.add_index :code_reviews, :issue, unique: true
    ActiveRecord::Base.connection.add_index :code_reviews, :created, order: :asc
    ActiveRecord::Base.connection.add_index :code_reviews, :owner_id
    ActiveRecord::Base.connection.add_index :code_reviews, :commit_hash
    # Physically re-arrange code_reviews by date so security_exp_participants is faster
    # ...although I'm not convinced it's making a difference.
    ActiveRecord::Base.connection.execute "CLUSTER code_reviews USING index_code_reviews_on_created"
  end

  def is_inspecting_vulnerability?
    not self.cvenums.empty? # if empty it's not checking vulnerability, thus return false 
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

  # An overlooked patchset is one that was created AFTER all approvals came in
  # It's a potential opportunity for un-reviewed code to be introduced.
  def overlooked_patchset?
    final_lgtm_date = nil
   
    #get all messages for this code review and iterate over them
    #to find the last message w/ approval message (LGTM)
    messages.order(date: :asc).each do |mess|
      if mess.approval == true
        final_lgtm_date = mess.date
      end
    end
    
    return false if final_lgtm_date.nil?

    patch_sets.order(created: :asc).each do|ps|
      return true if ps.created > final_lgtm_date #found one!
    end
    return false #none found
  end

  # Metric: 
  #  The developers who did not participate in the code inspection
  def nonparticipating_reviewers
    reviewers.where('dev_id NOT IN (SELECT dev_id FROM participants WHERE issue=?)', issue)
  end

  #returns the number of reviews of all the reviews added up
  def total_familiarity
    participants.sum(:reviews_with_owner)
  end
  
  def security_experienced_participants
    participants.where(security_experienced: true)  
  end

  # Determine whether or not total 
  # churn for all patchsets exceeds
  #
  # @param - lines of code
  # @return - boolean 
  def loc_per_hour_exceeded?(lines=200)
    date_approval_mess = nil
   
    #get all messages for this code review and iterate over them
    #to find 1st message w/ approval message (LGTM)
    self.messages.order(date: :asc).each do |mess|
      if mess.approval == true 
        date_approval_mess = mess.date
        break
      end
    end
    
    return false if date_approval_mess.nil?

    total_time_hours = ((date_approval_mess - self.created) / 60) / 60
    loc_per_hour = (self.total_churn / total_time_hours)
    if loc_per_hour > lines then return true else return false end
  end

end#class
