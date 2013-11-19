require_relative "../verify_base"

class CveVerify < VerifyBase

  def verify_issue_10854242_has_cve
    issue = CodeReview.where(issue: 10854242).first
    if issue.cve? == true then
      return_result(__method__, true)
    else
      return_result(__method__, false, "Issue 10854242 said it does not has a CVE when it does.")
    end
  end

  def verify_issue_23444043_has_no_cve
    issue = CodeReview.where(issue: 23444043).first
    if issue.cve? == false then
      return_result(__method__, true)
    else
      return_result(__method__, false, "Issue 23444043 said it has a CVE when it does not.")
    end
  end
  
end
