require_relative "../verify_base"

class CodeReviewAssociationVerify < VerifyBase

  def verify_code_review_10854242_reviewers
    c = CodeReview.find_by(issue: 10854242)
    assert_equal(5, c.reviewers.count,"Reviewer count is not right")
    assert_equal(1, c.reviewers.where(email: 'agl@chromium.org').count, "Email not found")
  end

  def verify_code_review_10854242_owner
    c = CodeReview.where(:issue => 10854242).take
    assert_equal("palmer@chromium.org", c.owner_email,"Owner email is not right")
  end
  
  def verify_commit_belongs_to_code_review
    assert_equal(5831706594508800, Commit.where(commit_hash: '6eebdee7851c52b1f481fca1cdffcbc51c8ec061').take.code_reviews.take.issue)
  end
  
  def verify_code_review_has_one_commit
    assert_equal('6eebdee7851c52b1f481fca1cdffcbc51c8ec061', CodeReview.where(issue: 5831706594508800).take.commit.commit_hash)
  end

end#end of class
