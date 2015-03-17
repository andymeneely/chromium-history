require_relative '../verify_base.rb'

class ProductionCountVerify < VerifyBase
  def verify_count_cves
    assert_equal 703, Cvenum.count
  end

  def verify_count_code_reviews
    assert_equal 207500, CodeReview.count
  end

  def verify_count_commits
    assert_equal 242635, Commit.count
  end

  def verify_release_owner_count
    assert_equal 13181134, ReleaseOwner.count
  end

  def verify_dangling_bug_commits
    query = <<-EOSQL
      SELECT COUNT(DISTINCT commit_bugs.bug_id) 
        FROM bugs RIGHT OUTER JOIN commit_bugs 
               ON bugs.bug_id=commit_bugs.bug_id 
        WHERE bugs.bug_id IS NULL
    EOSQL
    rs = ActiveRecord::Base.connection.execute query
    assert_equal 7159, rs.getvalue(0,0).to_i, "Number of expected dangling bug commits was wrong"
  end
end


