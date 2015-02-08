require_relative "../verify_base"

class TechnicalWordVerify < VerifyBase
  def verify_word_count
    assert_equal 202, TechnicalWord.count(:word)
  end

  def verify_word_associations
    assert_equal 339,  Comment.joins(:technical_words).count(:word)
    assert_equal 585,  Message.joins(:technical_words).count(:word)
  end
end