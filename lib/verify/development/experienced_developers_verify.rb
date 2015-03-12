require_relative "../verify_base"

class ExperiencedDevelopersVerify < VerifyBase

  def verify_participants_security_adjacencys
    #dev = Developer.find_by(email: 'senorblanco@chromium.org')
    #assert_equal [1], dev.participants.where('issue = 5831706594508800').pluck('security_adjacencys')
  end

end#class
