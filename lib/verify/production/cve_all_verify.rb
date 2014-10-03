require_relative '../verify_base'

class CveAllVerify < VerifyBase
  def verify_num_cves_have_one_issue
     query = <<-EOSQL
     SELECT COUNT(*) FROM cvenums 
      WHERE cve NOT IN 
        (SELECT cvenum_id FROM code_reviews_cvenums)
     EOSQL
     rs = ActiveRecord::Base.connection.execute query
     reviewless_cves = rs.getvalue(0,0).to_i

     # Through our own manual investigation, we know that some 
     # vulnerabilities don't trace to code reviews in trunk
     # We'll keep that number here for regression testing
     assert_equal 222, reviewless_cves, "All CVEs should have at least one code review."
  end
end
