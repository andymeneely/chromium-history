require_relative '../verify_base'

class FirstOwnershipVerify < VerifyBase

  def verify_no_duplicate_first_ownership
    assert_equal( FirstOwnership.pluck(:owner_email, :directory).uniq.count, FirstOwnership.pluck(:owner_email, :directory).count, "Total records vs. unique ones not matching")
  end
  
  def verify_all_owners_have_first_ownership
	assert_equal(ReleaseOwner.pluck(:owner_email).uniq.count,  FirstOwnership.pluck(:owner_email).uniq.count, "Some owners without first ownership recorded, count should match")
  end

  def verify_distinct_directory_owners_match_distinct_first_ownership
    assert_le( FirstOwnership.pluck(:directory).uniq.count, ReleaseOwner.pluck(:filepath).uniq.count, "Too many first ownerships recorded, count should not exceed owner directory count")
  end
  
  def verify_first_ownership_for_ALL
	first_own = FirstOwnership.where(owner_email: "ALL").take
    if first_own
      assert_equal(0, FirstOwnership.where(owner_email: "ALL").pluck(:dev_id)[0],"owner_email: ALL should have 1st ownership dev_id = 0")
	  assert_equal(false, first_own.releaseOwner.nil?,"No release owner association found")
    end
  end
  
  def verify_release_owner_association
	first_own = FirstOwnership.take
    assert_equal(false, first_own.releaseOwner.nil?,"No release owner association found")
  end
end
