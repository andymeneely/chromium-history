require_relative "../verify_base"

class LoadCompleteVerify < VerifyBase

  def verify_number_of_code_reviews
    verify_count("Code Reviews", 873, CodeReview.count)
  end

  def verify_number_of_commits
    verify_count("Commits", 1000, Commit.count)
  end

end
