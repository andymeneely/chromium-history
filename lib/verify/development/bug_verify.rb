require_relative "../verify_base"

class BugVerify < VerifyBase

   def verify_bug_id_20248_title
     assert_equal "OSX Omnibox context menu differs from Windows.", Bug.find_by(bug_id: 20248).title
   end

   def verify_bug_20248_stars
     assert_equal 5, Bug.find_by(bug_id: 20248).stars
   end

   def verify_bug_27675_status
     assert_equal "Fixed", Bug.find_by(bug_id: 27675).status
   end
   
   def verify_bug_20248_reporter
     assert_equal "shess@chromium.org", Bug.find_by(bug_id: 20248).reporter
   end
   
   def verify_bug_20248_opened
     assert_equal "2009-08-25 19:04:53 UTC", Bug.find_by(bug_id: 20248).opened.to_s
   end

   def verify_bug_20248_closed
     assert_equal "2009-09-21 16:51:21 UTC", Bug.find_by(bug_id: 20248).closed.to_s
   end

   def verify_bug_20248_modified
     assert_equal "2013-03-13 21:19:45 UTC", Bug.find_by(bug_id: 20248).modified.to_s
   end

   def verify_bug_20248_owner_email
     assert_equal "rohitrao@chromium.org", Bug.find_by(bug_id: 20248).owner_email
   end

   def verify_bug_20248_owner_uri
     assert_equal "/u/rohitrao@chromium.org/", Bug.find_by(bug_id: 20248).owner_uri
   end

#   def verify_bug_20248_content
#     assert_equal "shess@chromium.org", Bug.find_by(bug_id: 20248).reporter
#   end

end
