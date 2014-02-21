class CodeReview < ActiveRecord::Base
  has_many :patch_sets,  foreign_key: "code_review_id", primary_key: "issue"
  has_many :messages, foreign_key: "code_review_id", primary_key: "issue"
  has_many :reviewers, foreign_key: "issue", primary_key: "issue"
  has_many :ccs, foreign_key: "issue", primary_key: "issue"
  
  def self.on_optimize
    ActiveRecord::Base.connection.add_index :code_reviews, :issue, unique: true
  end

  def is_inspecting_vulnerability?
  	self.cve?
  end

  def contributors
    #anyone who commented on this code review
    codeReview = self.CodeReview;
    issueNumber = codeReview.issue;

    #take the issue number and look up in messages or comments
    mess = Message.find_by code_review_id: issueNumber;

    }
  end

end
