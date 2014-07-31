require_relative "../verify_base"                                                                      

class BlockVerify < VerifyBase                                                                           

  def verify_blocking_id                                                                       
    assert_equal 17941, Block.find_by(blocked_on_id: 12345).blocking_id
  end

  def verify_blocked_on_id                                                                       
    assert_equal 17941, Block.find_by(blocking_id: 67890).blocked_on_id
  end

end                                                                      
