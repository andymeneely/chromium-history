require_relative "../verify_base"                                                                      

class BlockVerify < VerifyBase                                                                           

  def verify_blocking_id                                                                       
    assert_equal 17941, Block.find_by(blocked_on_id: 12345).blocking_id
  end

  def verify_blocked_on_id                                                                       
    assert_equal 17941, Block.find_by(blocking_id: 67890).blocked_on_id
  end

  def verify_blocks_join_verify                                                                   
    assert_equal "1", Bug.find(17941).blocks.exists?(:blocking_id => 67890)
  end

  def verify_blocking_join_verify                                           
    assert_equal "1", Bug.find(17941).blocking.exists?(:blocked_on_id => 12345)
  end

end                                                                      
