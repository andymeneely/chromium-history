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
    rel_own = ReleaseOwner.where(owner_email:'sky@chromium.org',filepath:'net/ftp/ftp_directory_listing_parser_windows.h').take
    assert_equal("d882ed74b7d636714db50d3f6fe8b5f7939f4299", rel_own.first_ownership_sha, "firstOwnership not matching")
  end

  def verify_filepath_count_match_release_11
    rel_filepaths = ReleaseFilepath.where(release: "11.0").distinct(:thefilepath).select(:thefilepath).size
    rel_owners    = ReleaseOwner.where(release: "11.0").distinct(:filepath).select(:filepath).size
    assert_equal(rel_filepaths - 1, rel_owners, "Some filepaths are without owners, but count should match. Don't count ALL")
  end

end
