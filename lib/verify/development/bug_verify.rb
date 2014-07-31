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
end
