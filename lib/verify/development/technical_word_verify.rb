require_relative "../verify_base"

class TechnicalWordVerify < VerifyBase
  def verify_word_count
    assert_equal 232, TechnicalWord.count(:word)
  end

  def verify_word_associations
    assert_equal 619, Message.joins(:technical_words).size
    assert_equal 104, Commit.joins(:technical_words).size
    assert_equal 43, CodeReview.joins(:technical_words).size
  end
end
