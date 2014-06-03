require_relative "../verify_base"

class DateVerify < VerifyBase

  def verify_issue_10854242_created_date
    issue = CodeReview.where(issue: 10854242).first
    #remember to convert dates to strings for comparison
    if issue.created.to_s.eql?("2012-08-21 02:04:34 UTC") then 
      pass()
    else
      fail("Wrong created date on issue 10854242.")
    end
  end

  # Danielle: there is no patchset with this id, 
  #           also remember that patchset numbers are not unique,
  #      E.g. code reviews 10854242 and 23444043 both have a patchset number 1.
  #
  def verify_patchset_9141024_created_date
    patchset = PatchSet.where(code_review_id: 9141024, patchset: 3004).first
    #convert dates to strings for comparison
    if patchset.created.to_s.eql?("2012-01-20 23:53:25 UTC") then 
      pass()
    else
      fail("Wrong created date on patchset 9141024.")
    end
  end
  
end
