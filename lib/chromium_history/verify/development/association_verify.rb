require_relative "../verify_base"

class AssociationVerify < VerifyBase

  def verify_reviewers_for_filepath
    f = Filepath.where(filepath: 'ui/base/x/x11_util.cc').take 
    exp = ["agl@chromium.org", "ben@chromium.org", "darin@chromium.org", "derat@chromium.org", "kbr@chromium.org", "sadrul@chromium.org"]
    assert_equal exp, f.reviewers.pluck(:email).sort
  end

  def verify_filepath_vulnerable
    assert_equal true, Filepath.find_by(filepath: 'ui/base/x/x11_util.cc').vulnerable?
  end

  def verify_filepath_neutral
    assert_equal false, Filepath.find_by(filepath: 'content/renderer/media/webrtc_audio_renderer.cc').vulnerable?
  end

end#end of class
