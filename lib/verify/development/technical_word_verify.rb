require_relative "../verify_base"

class TechnicalWordVerify < VerifyBase
  def verify_word_count
    assert_equal 188, TechnicalWord.count(:word)
  end

  def verify_word_associations
    assert_equal 584, Message.joins(:technical_words).size
    assert_equal 87, Commit.joins(:technical_words).size
    assert_equal 39, CodeReview.joins(:technical_words).size
  end
end
