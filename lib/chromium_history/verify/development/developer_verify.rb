require_relative "../verify_base"

class DeveloperVerify < VerifyBase

  def verify_watch_email
    assert_equal("yusukes@chromium.org", Developer.where("email like ?","yusukes%").take[:email],"Email +appenders not being ignored")
  end

end#end of class
