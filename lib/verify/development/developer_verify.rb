require_relative "../verify_base"

class DeveloperVerify < VerifyBase

  def verify_watch_email
    assert_equal("ben@chromium.org", Developer.where("email like ?","ben%").take[:email],"Email +appenders not being ignored")
  end

  def verify_blacklisted_email_local?
    assert_equal(true, Developer.blacklisted_email_local?("chromium-reviews"), "chromium-reviews should be blacklisted")
    assert_equal(true, Developer.blacklisted_email_local?("reply") , "reply should be blacklisted")
    assert_equal(false, Developer.blacklisted_email_local?("GLaDOS") , "GLaDOS should not be blacklisted")
  end 

  def verify_blacklisted_email_domain?
    assert_equal(true, Developer.blacklisted_email_domain?("googlegroups.com"),"googlegroups.com should be blacklisted")
    assert_equal(false, Developer.blacklisted_email_domain?("aperturescience.gov"), "aperturescience.gov shouldn't be blacklisted")
  end

end#end of class
