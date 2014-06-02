require_relative 'verify_base'

class CveAllVerify < VerifyBase
  def verify_all_cves_have_one_issue
     rs = ActiveRecord::Base.connection.execute "SELECT COUNT(*) FROM cvenums WHERE cve NOT IN (SELECT cvenum_id FROM code_reviews_cvenums)"
     reviewless_cves = rs.getvalue(0,0).to_i 
     assert_equal 0, reviewless_cves, "All CVEs should have at least one code review."
  end
end
