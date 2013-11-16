require_relative "../verify_base"

class DateVerify < VerifyBase

  def verify_issue_10854242_created_date
    issue = CodeReview.where(issue: 10854242).first
    #remember to convert dates to strings for comparison
    if issue.created.to_s.eql?("2012-08-21 02:04:34 UTC") then 
      return_result(__method__, true)
    else
      return_result(__method__, false, "Wrong created date on issue 10854242.")
    end
  end

  #TODO: finish checking patch set dates
  def verify_patchset_9141024_created_date
    patchset = PatchSet.where(patchset: 9141024).first
    #remember to convert dates to strings for comparison
    if patchset.created.to_s.eql?("2012-01-20 23:53:25 UTC") then 
      return_result(__method__, true)
    else
      return_result(__method__, false, "Wrong created date on patchset 9141024.")
    end
  end
  
end
