require_relative "../verify_base"

class ExperiencedDevelopersVerify < VerifyBase

  def verify_participants_security_adjacencys
    dev = Developer.find_by(email: 'laforge@chromium.org')
    assert_equal [1], dev.participants.where('issue = 52823002').pluck('security_adjacencys')
  end
  
  def verify_participants_no_sec_adjacencys
    dev = Developer.find_by(email: 'laforge@chromium.org')
    assert_equal [0], dev.participants.where('issue = 18533').pluck('security_adjacencys')
  end

end#class
