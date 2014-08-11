require_relative "../verify_base"

class BugLabelVerify < VerifyBase

  def verify_label_17941_count
    assert_equal 8, BugLabel.where(bug_id: 17941).count
  end
  
  def verify_label_17941_count_2
    assert_equal 8, Bug.find(17941).labels.count
  end

  def verify_label_17941_exists
    assert_equal "1", Bug.find(17941).labels.exists?(:label => "bulkmove") 
  end

  def verify_os_all_bug_ids
    assert_equal [17941,27675],Bug.joins(:labels).where("labels.label" => 'os-all').pluck(:bug_id)
  end
  
  def verify_ReleaseBlock_Beta_count
    assert_equal 3,Label.find("releaseblock-beta").bugs.count
  end
end
