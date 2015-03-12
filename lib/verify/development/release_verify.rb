require_relative '../verify_base'

class ReleaseVerify < VerifyBase

  def verify_23_files_in_release_11
    rfs = Release.find_by(name: '11.0').release_filepaths
    assert_equal 19, rfs.count
    assert_equal 'ash/wm/system_modal_container_layout_manager.cc', rfs.order(:thefilepath).first.thefilepath
  end

  def verify_release_11_date
    assert_equal '2011-01-28', Release.find_by(name: '11.0').date.strftime('%F')
  end

  def verify_release_11_ftp_util_num_reviewers
    assert_equal 2, ReleaseFilepath.find_by(release: '11.0', thefilepath: 'net/ftp/ftp_util.h').num_reviewers
  end

  def verify_release_12_ftp_util_num_reviewers
    assert_equal 2, ReleaseFilepath.find_by(release: '11.0', thefilepath: 'net/ftp/ftp_util.h').num_reviewers
  end

  def verify_ftp_directory_sloc
    assert_equal 21, ReleaseFilepath.where(release: '11.0', thefilepath: 'net/ftp/ftp_directory_listing_parser_windows.h').pluck(:sloc).last
  end

  def verify_ftp_directory_sloc_release_11
    assert_equal 21, ReleaseFilepath.find_by(release: '11.0', thefilepath: 'net/ftp/ftp_directory_listing_parser_windows.h').sloc
  end

  def verify_ftp_directory_sloc_release_12
    assert_equal 6, ReleaseFilepath.find_by(release: '12.0', thefilepath: 'net/ftp/ftp_directory_listing_parser_windows.h').sloc
  end

  def verify_source_code
    assert_equal true, ReleaseFilepath.source_code?('ui/surface/transport_dib_linux.cc')
  end

  def verify_not_source_code
    assert_equal false, ReleaseFilepath.source_code?('build/internal/release_impl.vsprops')
  end

  def verify_makefile_included
    assert_equal true, ReleaseFilepath.source_code?('ui/aura/Makefile')
  end

  def verify_regression_example_counts
    rf = ReleaseFilepath.find_by(thefilepath: 'net/ftp/ftp_directory_listing_parser_windows.h', release: '11.0')
    assert_equal(1, rf.num_reviews)
    assert_equal(2, rf.num_reviewers)
    assert_equal(3, rf.num_participants)
    assert_equal(0, rf.num_security_experienced_participants.to_i)
    assert_equal(0, rf.avg_security_experienced_participants.to_i)
    #assert_equal(3, rf.security_adjacencys)
    assert_equal(true, (rf.avg_sheriff_hours - 0.0).abs < 0.01)
    assert_equal(true, (rf.perc_fast_reviews - 1.0).abs < 0.01)
  end
end

