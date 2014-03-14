class CodeReview < ActiveRecord::Base
  has_many :patch_sets,  foreign_key: "code_review_id", primary_key: "issue"
  has_many :messages, foreign_key: "code_review_id", primary_key: "issue"
  has_many :reviewers, foreign_key: "issue", primary_key: "issue"
  has_many :ccs, foreign_key: "issue", primary_key: "issue"

  has_one :commit, foreign_key: "code_review_id", primary_key: "issue"
  
  has_and_belongs_to_many :cvenums
  
  def self.on_optimize
    ActiveRecord::Base.connection.add_index :code_reviews, :issue, unique: true
  end

  def is_inspecting_vulnerability?
  	self.cve?
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
    
  end

end
