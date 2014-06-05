require_relative '../verify_base'

class ReleaseVerify < VerifyBase

  def verify_23_files_in_release_11
    rfs = Release.find_by(name: '11.0').release_filepaths
    assert_equal 23, rfs.count
    assert_equal 'ash/wm/system_modal_container_layout_manager.cc', rfs.order(:thefilepath).first.thefilepath
  end

  def verify_release_11_date
    assert_equal '2011-01-28', Release.find_by(name: '11.0').date.strftime('%F')
  end

  def verify_release_11_ftp_util_num_reviewers
    assert_equal 2, ReleaseFilepath.find_by(thefilepath: 'net/ftp/ftp_util.h').num_reviewers
  end

end
