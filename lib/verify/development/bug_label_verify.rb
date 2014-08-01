require_relative "../verify_base"

class BugLabelVerify < VerifyBase

  def verify_label_17941_count
    assert_equal 9, BugLabel.where(bug_id: 17941).count
  end
  
  def verify_label_17941_count_2
    assert_equal 9, Bug.find(17941).labels.count
  end

  def verify_label_17941_exists
    assert_equal "1", Bug.find(17941).labels.exists?(:label => "Type-Bug-Regression") 
  end

  def verify_os_all_bug_ids
    assert_equal [17941,27675],Bug.joins(:labels).where("labels.label" => 'OS-All').pluck(:bug_id)
  end
end
