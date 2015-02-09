require_relative "../verify_base"

class ExperiencedDevelopersVerify < VerifyBase

  def verify_participants_security_adjacencys
    assert_equal [1], Developer.find(6).participants.where('issue = 5831706594508800').pluck('security_adjacencys')
  end

end#class