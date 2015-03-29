require_relative "../verify_base"

class TechnicalWordVerify < VerifyBase
  def verify_word_count
    assert_equal 236, TechnicalWord.count(:word)
  end

  def verify_word_associations
    assert_equal 442, Message.joins(:technical_words).size
    assert_equal 110, Commit.joins(:technical_words).size
    assert_equal 44, CodeReview.joins(:technical_words).size
    assert_equal 44132, AcmCategory.joins(:technical_words).size
  end
end
