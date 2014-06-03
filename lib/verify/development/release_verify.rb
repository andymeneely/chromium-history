require_relative '../verify_base'

class ReleaseVerify < VerifyBase

  def verify_23_files_in_release_11
    rfs = Release.find_by(name: '11.0').release_filepaths
    assert_equal 23, rfs.count
    assert_equal 'ash/wm/system_modal_container_layout_manager.cc', rfs.order(:filepath).first.filepath.filepath
  end

  def verify_release_11_date
    assert_equal '2011-01-28', Release.find_by(name: '11.0').date.strftime('%F')
  end

end
