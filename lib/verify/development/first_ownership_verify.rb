require_relative '../verify_base'

class FirstOwnershipVerify < VerifyBase

  def verify_all_owners_have_first_ownership
	assert_equal(false, ReleaseOwner.where("first_ownership_sha is null ").present?, "Some owners without first ownership recorded, blank field found")
  end

  def verify_distinct_directory_ownerships_not_exceed_recorded_filepaths
    assert_le( ReleaseOwner.pluck(:directory).uniq.count, ReleaseOwner.pluck(:filepath).uniq.count, "Too many first ownerships recorded, count should not exceed owner filepath count")
  end

  def verify_release_owner_association
	first_own = ReleaseOwner.where(owner_email:'sky@chromium.org',directory:'net/')
    assert_equal(2, first_own.count,"Wrong release owner association found")
  end
end
