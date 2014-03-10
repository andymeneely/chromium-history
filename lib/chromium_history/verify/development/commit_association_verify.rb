require_relative '../verify_base'

class CommitAssociationVerify < VerifyBase
  def verify_reviewers_for_6eebdee
    assert_equal 4, Commit.where(commit_hash: '6eebdee7851c52b1f481fca1cdffcbc51c8ec061').take.reviewers.count
    assert_equal ['danakj@chromium.org','ojan@chromium.org','skaslev@chromium.org','skaslev@google.com'], Commit.where(commit_hash: '6eebdee7851c52b1f481fca1cdffcbc51c8ec061').take.reviewers.pluck(:email).to_a.sort

  end

  def verify_commit_filepath_to_cve
    cf = CommitFilepath.where(filepath: 'ui/base/x/x11_util.cc').take
    assert_equal false, cf.commit.code_review.cvenums.empty?
  end
end

