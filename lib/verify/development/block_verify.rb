require_relative "../verify_base"                                                      

class BlockVerify < VerifyBase                                                      
  def verify_blocked_on_id                                                        
    assert_equal 17941, Block.find_by(blocking_id: 67890).bug_id
  end

  def verify_blocks_join_verify   
    assert_equal "1", Bug.find(17941).blocks.exists?(:blocking_id => 67890)
  end

  def verify_blocks_join_verify_2  
    assert_equal "Fixed", Bug.joins(:blocks).where("blocks.blocking_id" => 17941).pluck("bugs.status").first
  end

  def verify_blocks_join_verify_3  
    assert_equal "Invalid", Bug.joins(:blocks).where("blocks.blocking_id" => 20248).pluck("bugs.status").first
  end

end                                                                      
