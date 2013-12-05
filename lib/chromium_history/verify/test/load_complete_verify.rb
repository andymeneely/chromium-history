require_relative "../verify_base"

class LoadCompleteVerify < VerifyBase

  def verify_number_of_code_reviews
    verify_count("Code Reviews", 873, CodeReview.count)
  end

  def verify_number_of_commits
    verify_count("Commits", 1000, Commit.count)
  end

  private
  def verify_count(name, expected, actual)
    if actual > expected
      fail("More than #{expected} #{name} found. Actual: #{actual}")
    elsif actual < expected
      fail("Less than #{expected} #{name} found. Actual: #{actual}")
    else
      pass()
    end
  end

end
