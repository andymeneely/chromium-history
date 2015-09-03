require_relative "../verify_base"

class TechnicalWordVerify < VerifyBase
  def verify_word_count
    assert_equal 71, TechnicalWord.count(:word)
  end

  def verify_word_associations
    assert_equal 74, Message.joins(:technical_words).size
    assert_equal 26, Commit.joins(:technical_words).size
    assert_equal 11, CodeReview.joins(:technical_words).size
    assert_equal 7527, AcmCategory.joins(:technical_words).size
  end
end
