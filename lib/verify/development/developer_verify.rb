require_relative "../verify_base"

class DeveloperVerify < VerifyBase

  def verify_watch_email
    assert_equal("ben@chromium.org", Developer.where("email like ?","ben%").take[:email],"Email +appenders not being ignored")
  end

  def verify_blacklisted_email_local_chomium_reviews
    assert_equal(true, Developer.blacklisted_email_local?("chromium-reviews"), "chromium-reviews should be blacklisted")
  end

  def verify_blacklisted_email_local_reply
    assert_equal(true, Developer.blacklisted_email_local?("reply") , "reply should be blacklisted")
  end

  def verify_blacklisted_email_local_not_blacklisted
    assert_equal(false, Developer.blacklisted_email_local?("GLaDOS") , "GLaDOS should not be blacklisted")
  end 

  def verify_blacklisted_email_domain_googlegroups
    assert_equal(true, Developer.blacklisted_email_domain?("googlegroups.com"),"googlegroups.com should be blacklisted")
  end
  
  def verify_blacklisted_email_domain_not_blacklisted
    assert_equal(false, Developer.blacklisted_email_domain?("aperturescience.gov"), "aperturescience.gov shouldn't be blacklisted")
  end

  def verify_blacklisted_email_reply
    assert_equal(true, Developer.blacklisted_email?("reply@chromium.org"), "Anything with 'reply' as the local should be blacklisted")
  end

  def verify_blacklisted_email_googlegroups
    assert_equal(true, Developer.blacklisted_email?("bob@googlegroups.com"), "Anything with 'googlegroups,com' as the doman should be blacklisted")
  end

  def verify_blacklisted_email_not_blacklisted
    assert_equal(false, Developer.blacklisted_email?("GLaDOS@aperturescience.gov"), "Should not be blacklisted")
  end

end#end of class
