require_relative "../verify_base"

class BugLabelVerify < VerifyBase

  def verify_label_17941_count
    assert_equal 9, BugLabel.where(bug_id: 17941).count
  end

  def verify_os_all_bug_ids
  end
end
