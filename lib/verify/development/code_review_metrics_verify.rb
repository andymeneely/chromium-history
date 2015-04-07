require_relative '../verify_base.rb'

class CodeReviewMetricsVerify < VerifyBase

  def verify_is_inspecting_vulnerability?
    assert_equal true, CodeReview.find_by(issue: 10854242).is_inspecting_vulnerability? # Rietveld id in cves.csv 
    assert_equal false, CodeReview.find_by(issue: 23444043).is_inspecting_vulnerability? # Rietveld id not in cves.csv
  end

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

  def verify_5831706594508800_loc_per_hour_exceeded?
    assert_equal true, CodeReview.find_by(issue: 5831706594508800).loc_per_hour_exceeded? #approver looked at 111 loc in three minutes
  end

  def verify_23444043_total_familiarity
    # Code Review 23444043 
    #   * Had two participants: tommi@chromium.org and xians@chromium.org
    #   * Was on 2013-09-10
    #   * Owner was tommi@chromium.org, so really one external participant
    # xians@chromium.org was also on 8818012 where tommi was the owner. 
    assert_equal 1, CodeReview.find_by(issue: 23444043).total_familiarity
  end

  def verify_52823002_security_experienced
    cr = CodeReview.find_by(issue: 52823002)
    emails = cr.security_experienced_participants.joins(:developer)\
      .order('developers.email').pluck('developers.email')
    assert_equal ['darin@chromium.org','derat@chromium.org', 'laforge@chromium.org'],emails
  end

  def verify_23444043_total_reviews_with_owner
    assert_equal 1, CodeReview.find_by(issue: 23444043).total_reviews_with_owner
  end

  def verify_23444043_owner_familiarity_gap
    assert_equal 1, CodeReview.find_by(issue: 23444043).owner_familiarity_gap
  end

  def verify_23454014_total_sheriff_hours
    assert_equal 96, CodeReview.find_by(issue: 23454014).total_sheriff_hours
  end

end
