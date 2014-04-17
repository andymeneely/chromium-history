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

  def contributors
    #anyone who commented on this code review
    issueNumber = self.issue
    #take the issue number and look up in messages or comments
    mess = Message.where("code_review_id = ?", issueNumber)
    contri = Array.new
    for m in mess 
      txt = m.text
      if txt.length > 20
        puts m.sender
        contri.push(m.sender) unless contri.include?(m.sender)
      end
    end
    return contri
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

  #
  # Number of Security Experienced Participants
  # Return the number of participants that have
  # secuirty experience who has participated
  # in a code review that also involved a 
  # CVE. 
  def num_security_experienced_parts


  end#num_security_experienced_parts

end
