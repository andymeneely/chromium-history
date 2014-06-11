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

  def verify_filepath_not_vuln_after
    assert_equal false, Filepath.find_by(filepath: 'ui/base/x/x11_util.cc').vulnerable?(DateTime.new(2014,01,01))
  end

  def verify_filepath_neutral
    assert_equal false, Filepath.find_by(filepath: 'content/renderer/media/webrtc_audio_renderer.cc').vulnerable?
  end

  def verify_participants_for_code_review
    assert_equal 6, CodeReview.find_by(issue: 10854242).participants.count
  end

  def verify_participants_for_dev
    assert_equal 1, Developer.find_by(email: 'enne@chromium.org').participants.count
  end

  def verify_filepath_participants
    assert_equal [37,38], Filepath.participants.where(filepath: "DEPS").pluck(:dev_id)
  end

  def verify_filepath_contributors_empty
    assert_equal [],  Filepath.contributors.where(filepath: "DEPS").pluck(:dev_id)
  end

  def verify_filepath_three_contributors
    contrib_devs = Filepath.contributors.where(filepath: "net/ftp/ftp_util.h").pluck(:dev_id)   
    assert_equal [],(contrib_devs-[30,31,20]) 
  end

end#end of class
