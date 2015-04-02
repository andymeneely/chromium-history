require_relative '../verify_base'

class FirstOwnershipVerify < VerifyBase

  def verify_all_owners_have_first_ownership
    assert_equal(false, ReleaseOwner.where("first_ownership_sha IS NULL").present?, "Some owners without first ownership recorded, blank field found")
  end
  
  def verify_all_owners_have_first_commit_data
    #assert_equal(false, ReleaseOwner.where("first_dir_commit_sha IS NULL").present?, "Some owners without first commit data recorded, blank field found")
  end
  
  def verify_all_owners_have_commits_metrics
    #assert_equal(false, ReleaseOwner.where("dir_commits_to_ownership IS NULL OR dir_commits_to_release IS NULL").present?, "Some owners without commits to ownership data, blank field found")
  end  

  def verify_consistent_data_same_owner_and_dir_sky_ui
    first_owns = ReleaseOwner.where(owner_email:'sky@chromium.org',directory:'ui/').take(2)
    assert_equal(first_owns[1].first_dir_commit_sha,first_owns[0].first_dir_commit_sha,"Inconsistent first ownership data for same owner-directory")
    assert_equal(first_owns[0].dir_commits_to_ownership,first_owns[1].dir_commits_to_ownership,"Inconsistent commits to ownership data for same owner-directory")
  end
  
  def verify_correct_first_dir_commit_sha_date_match
    #assert_equal(Commit.where(commit_hash: 'b9b1e7a4fa49c108c40536cee59ce0b2b0a09d86').take.created_at,ReleaseOwner.where(owner_email:'sky@chromium.org',directory:'ui/').take.first_dir_commit_date,"wrong date for first commit hash")
  end

  def verify_right_count__number_of_commits_to_own_ddorwin_third_party
    #assert_equal(10,ReleaseOwner.where(owner_email:'ddorwin@chromium.org',directory:'third_party/').take.dir_commits_to_ownership,"Wrong total of commits to files in directory for ddorwin in third_party/")
  end

  def verify_distinct_directory_ownerships_not_exceed_recorded_filepaths
    assert_le( ReleaseOwner.pluck(:directory).uniq.count, ReleaseOwner.pluck(:filepath).uniq.count, "Too many first ownerships recorded, count should not exceed owner filepath count")
  end

  def verify_release_owner_ownership_count
    first_own = ReleaseOwner.where(owner_email:'sky@chromium.org',directory:'ui/')
    assert_equal(3, first_own.count,"Wrong count of ownersips")
  end
end
