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
    assert_equal(false, Developer.blacklisted_email_domain?("aperturescience.gov"),"aperturescience.gov shouldn't be blacklisted")
  end

  def verify_sanitize_validate_email_tag
    assert_equal(["rouslan@chromium.org",true], Developer.sanitize_validate_email("rouslan+watch@chromium.org"), "Tag isn't being removed")
  end

  def verify_sanitize_validate_email_google_to_chromium
    assert_equal(["aa@chromium.org", true], Developer.sanitize_validate_email("aa@google.com"), "Domain isn't being changed from google.com to chromium.org")	
  end

  def verify_sanitize_validate_email_chormium_to_chromium
    assert_equal(["bob@chromium.org", true], Developer.sanitize_validate_email("bob@chormium.org"), "Domain isn't being changed from chormium.org to chromium.org")	
  end

  def verify_sanitize_validate_email_blacklisted
    assert_equal([nil, false], Developer.sanitize_validate_email("me@googlegroups.com"), "Email shouldn't be valid because it is blacklisted")	
  end

  def verify_sanitize_validate_email_gtempaccount
    assert_equal(["dgozman@chromium.org", true], Developer.sanitize_validate_email("dgozman%chromium.org@gtempaccount.com"), 
		 "Email should be valid and switched to orginal domain")	
  end

  def verify_sanitize_validate_commit_bot_gtemp
    assert_equal [nil,false],\
                 Developer.sanitize_validate_email("commit-bot%chromium.org@gtempaccount.com"),\
                 "Commit bot should be blacklisted"
  end

  # def verify_contribution_txt
  #   assert_equal false, Contributor.contribution?("0123456789")
  #   assert_equal true, Contributor.contribution?("a" * 51)
  # end

  def verify_search_or_add_invalid
    assert_equal nil, Developer.search_or_add('me@googlegroups.com'), "email is invalid"
  end

  def verify_search_or_add_email_exists
    assert_equal 'danakj@chromium.org', Developer.search_or_add('danakj@chromium.org').email, "danakj@chromium.org already exists in the db" 
  end

  def verify_search_or_add_new_email
    assert_equal 'newemail@chromium.org', Developer.search_or_add('newemail@chromium.org').email, "newemail@chromium.org needs to be added to the db"
    dev_id = Developer.where(email: 'newemail@chromium.org').pluck(:id)
    Developer.delete(dev_id)
  end
  
end#end of class
