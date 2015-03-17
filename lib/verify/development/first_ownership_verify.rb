require_relative '../verify_base'

class FirstOwnershipVerify < VerifyBase

  def verify_all_owners_have_first_ownership
    assert_equal(false, ReleaseOwner.where("first_ownership_sha IS NULL").present?, "Some owners without first ownership recorded, blank field found")
  end
  
  def verify_all_owners_have_first_commit_data
    assert_equal(false, ReleaseOwner.where("first_dir_commit_sha IS NULL").present?, "Some owners without first commit data recorded, blank field found")
  end
  
  def verify_all_owners_have_commits_metrics
    assert_equal(false, ReleaseOwner.where("dir_commits_to_ownership IS NULL OR dir_commits_to_release IS NULL").present?, "Some owners without commits to ownership data, blank field found")
  end  

  def verify_distinct_directory_ownerships_not_exceed_recorded_filepaths
    assert_le( ReleaseOwner.pluck(:directory).uniq.count, ReleaseOwner.pluck(:filepath).uniq.count, "Too many first ownerships recorded, count should not exceed owner filepath count")
  end

  def verify_release_owner_ownership_count
    first_own = ReleaseOwner.where(owner_email:'sky@chromium.org',directory:'ui/')
    assert_equal(3, first_own.count,"Wrong count of ownersips")
  end
end
