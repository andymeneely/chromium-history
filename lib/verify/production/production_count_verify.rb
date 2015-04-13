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
    assert_equal 9770692, ReleaseOwner.count
  end

  def verify_commit_filepath_counts
    assert_equal 1890851, CommitFilepath.count
  end

  def verify_participant_count
    assert_equal 429321, Participant.count
  end

  def verify_reviewer_count
    assert_equal 325836, Reviewer.count
  end

  def verify_bug_count
    assert_equal 374686, Bug.count
  end

  def verify_commit_bug_count
    assert_equal 138020, CommitBug.count
  end

  def verify_release_filepath_count
    assert_equal 113923, ReleaseFilepath.count
  end

  def verify_adjacency_count
    query = 'SELECT COUNT(*) FROM adjacency_list'
    rs = ActiveRecord::Base.connection.execute query
    assert_equal 393680, rs.getvalue(0,0).to_i
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


