require_relative "../verify_base"

class CveVerify < VerifyBase

  def verify_issue_10854242_has_cve
    assert_equal 1, CodeReview.where(issue: 10854242).first.cvenums.count, "Issue 10854242 should have one CVE"
  end

  def verify_issue_23444043_has_no_cve
    assert_equal 0,CodeReview.where(issue: 23444043).first.cvenums.count, "Issue 23444043 should have no CVEs"
  end

  def verify_bounties
    assert_equal 1337, Cvenum.find_by(cve: 'CVE-2008-6994').bounty.to_i
    assert_equal 0, Cvenum.find_by(cve: 'CVE-2009-0411').bounty.to_i

  end
  
end
