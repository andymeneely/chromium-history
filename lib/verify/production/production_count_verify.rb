require_relative '../verify_base.rb'

class ProductionCountVerify < VerifyBase
  def count_cves
    assert_equal 672, Cvenum.count
  end

  def count_code_reviews
    assert_equal 159254, CodeReview.count
  end

  def count_commits
    assert_equal 185970, Commit.count
  end
end


