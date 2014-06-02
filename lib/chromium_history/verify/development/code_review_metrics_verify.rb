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

  def verify_10854242_max_churn
    assert_equal 49, CodeReview.find_by(issue: 10854242).max_churn  
  end

  def verify_10854242_no_overlooked_patchsets
    assert_equal false, CodeReview.find_by(issue: 10854242).overlooked_patchset?
  end
  
  def verify_9141024_overlooked_patchsets
    assert_equal true, CodeReview.find_by(issue: 9141024).overlooked_patchset?
  end

  def verify_10854242_num_nonparticipating_reviewers
    assert_equal 2, CodeReview.find_by(issue: 10854242).nonparticipating_reviewers.count
  end

end
