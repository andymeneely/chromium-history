require_relative "../verify_base"

class ReleaseOwnersVerify < VerifyBase

  def verify_dev_id_all_owners
    assert_equal(0, ReleaseOwner.where(owner_email: "ALL").pluck(:dev_id)[0],"owner_email: ALL should have dev_id = 0")
  end

  def verify_no_duplicate_ownership
    assert_equal(ReleaseOwner.find(:all).uniq.count, ReleaseOwner.find(:all).count, "Ownership records should be unique")
  end

  def verify_release_association
	rel_own = ReleaseOwner.take
    assert_equal(false, rel_own.release.nil? , "No release association found")
  end

  def verify_filepath_association
	rel_own = ReleaseOwner.take
    assert_equal(false, rel_own.filepath.nil? , "No filepath association found")
  end 

  def verify_dev_association
	rel_own = ReleaseOwner.take
    assert_equal(false, rel_own.developer.nil?,"No developer association found")
  end

  def verify_filepath_count_match
    assert_equal( Filepath.pluck(:filepath).uniq.count, ReleaseOwner.pluck(:filepath).uniq.count, "Some filepaths without owners, count should match")
  end

end