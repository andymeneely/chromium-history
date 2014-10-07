require_relative "../verify_base"

class AssociationVerify < VerifyBase

  def verify_reviewers_for_filepath
    f = Filepath.where(filepath: 'ui/base/x/x11_util.cc').take 
    exp = ["agl@chromium.org", "ben@chromium.org", "darin@chromium.org", "derat@chromium.org", "kbr@chromium.org", "sadrul@chromium.org"]
    assert_equal exp, f.reviewers.pluck(:email).sort
  end

  def verify_filepath_bug_count
    assert_equal 2, Filepath.find_by(filepath: 'cc/resources/texture_mailbox_deleter.h').bugs.count
  end
  
  def verify_filepath_bug_count_by_date
    dates = DateTime.new(1970,01,01)..DateTime.new(2009,8,26)
    assert_equal 1, Filepath.find_by(filepath: 'cc/resources/texture_mailbox_deleter.h').bugs(dates).count
  end
  
  def verify_filepath_bug_by_label
    dates = DateTime.new(1970,01,01)..DateTime.new(2050,1,1)
    labels = 'type-bug-security'
    assert_equal 1, Filepath.find_by(filepath: 'cc/resources/texture_mailbox_deleter.h').bugs(dates,labels).count
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
    assert_equal ['apatrick@chromium.org','nduca@chromium.org'], Filepath.participants.where(filepath: "DEPS").pluck(:email).sort
  end

  def verify_filepath_contributors_empty
    assert_equal [],  Filepath.contributors.where(filepath: "DEPS").pluck(:email)
  end

  def verify_filepath_three_contributors
    contrib_devs = Filepath.contributors.where(filepath: "net/ftp/ftp_util.h").pluck(:email).sort
    assert_equal ['eroman@chromium.org','phajdan.jr@chromium.org','wtc@chromium.org'],contrib_devs
  end

  def verify_participants_on_filepath
    f = Filepath.where(filepath: "DEPS")
    assert_equal ['apatrick@chromium.org','nduca@chromium.org'], f.participants.pluck(:email).sort
  end
end#end of class
