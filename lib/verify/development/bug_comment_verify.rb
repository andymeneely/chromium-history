require_relative "../verify_base"

class BugCommentVerify < VerifyBase

  def verify_bug_17941_comment_count
    assert_equal 10, BugComment.where(bug_id: 17941).count
  end

  def verify_bug_17941_comment_updated
    cpus_comment = BugComment.where(bug_id: 17941, author_email: 'cpu@chromium.org').pluck(:updated).first
    assert_equal '07/29/2009', cpus_comment.strftime("%m/%d/%Y")
  end

  def verify_bug_17941_comment_author_uri
    assert_equal '/u/kuchhal@chromium.org/', BugComment.where(author_email: 'kuchhal@chromium.org').pluck(:author_uri).first
  end

  def very_bug_17941_comment_content
    assert_equal 'Installed from filer only !' , BugComment.where(author_uri: '/u/103485851777014287537/').pluck(:content).first
  end
end
