require_relative '../verify_base'

class ReleaseOwnersVerify < VerifyBase
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

  def verify_first_ownership_association
    rel_own = ReleaseOwner.where(owner_email:'sky@chromium.org',filepath:'ash/wm/system_modal_container_layout_manager.cc').take
    assert_equal("75fee3776f2e159d8e52bb13bb4545ac46021512", rel_own.first_ownership_sha, "firstOwnership not matching")
  end

  def verify_filepath_count_match_release_11
    rel_filepaths = ReleaseFilepath.where(release: "11.0").distinct(:thefilepath).select(:thefilepath).size
    rel_owners    = ReleaseOwner.where(release: "11.0").distinct(:filepath).select(:filepath).size
    assert_equal(6, rel_owners, "Some filepaths are without owners, but count should match. Don't count ALL")
  end

  def verify_num_owners_x11_cc
    rf = ReleaseFilepath.find_by(thefilepath: 'ui/views/widget/desktop_aura/desktop_root_window_host_x11.cc', release: '11.0')
    assert_equal(3, rf.num_owners, 'num_owners not loaded properly')
  end

end

