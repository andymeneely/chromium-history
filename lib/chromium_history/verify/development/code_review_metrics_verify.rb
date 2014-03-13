require_relative '../verify_base.rb'

class CodeReviewMetricsVerify < VerifyBase

  def verify_10854242_1_1_churn
    psf = CodeReview.find_by(issue: 10854242).patch_sets.find_by(patchset: 1).patch_set_files.find_by(filepath: 'ui/surface/transport_dib_linux.cc')
    assert_equal 5, psf.churn
  end

  def verify_10854242_1_churn
    assert_equal 7, CodeReview.find_by(issue: 10854242).patch_sets.find_by(patchset: 1).churn
  end

  def verify_10854242_total_churn
    assert_equal 149, CodeReview.find_by(issue: 10854242).total_churn
  end
end
