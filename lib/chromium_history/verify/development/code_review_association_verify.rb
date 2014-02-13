require_relative "../verify_base"

class CodeReviewAssociationVerify < VerifyBase

  def verify_code_review_10854242_reviewers
    c = CodeReview.where(:issue => 10854242).take
    assert_equal(5, c.reviewers.count,"Reviewer count is not right")
    assert_equal(1, c.reviewers.where(:developer => 'agl@chromium.org').count, "Email not found")
  end

end#end of class
