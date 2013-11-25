require_relative "../verify_base"

class LoadCompleteVerify < VerifyBase

  def verify_exactly_995_code_reviews_exist
    verify_count("Code Reviews", 995, CodeReview.count)
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
