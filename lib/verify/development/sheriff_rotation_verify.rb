require_relative "../verify_base"

class SheriffRotationVerify < VerifyBase

  def verify_start_dates
    dev_id = Developer.where(email: 'sadrul@chromium.org').pluck(:id)
    sadrul_start = SheriffRotation.where(dev_id: dev_id).pluck(:start)
    assert_equal '07/13/2011', sadrul_start.first.strftime("%m/%d/%Y"), "sadrul's first rotation should be 12/07/11"
    assert_equal '12/05/2013', sadrul_start.last.strftime("%m/%d/%Y"), "sadrul's last rotation should be 12/05/2013"
  end

  def verify_title
    dev_id = Developer.where(email: 'kbr@chromium.org').pluck(:id)
    kbr_title = SheriffRotation.where(dev_id: dev_id).pluck(:title)
    assert_equal 'Chrome GPU Pixel Wrangling', kbr_title.first, "kbr did Chrome GPU Pixel Wrangling"  
  end

  def verify_duration
    dev_id = Developer.where(email: 'danakj@chromium.org').pluck(:id)
    danakj_dur = SheriffRotation.where(dev_id: dev_id).pluck(:duration)
    assert_equal 48, danakj_dur.first, "danakj's first rotation was 48 hours"
  end

  def verify_rotations
    dev_id = Developer.where(email: 'danakj@chromium.org').pluck(:id)
    assert_equal 3, SheriffRotation.where(dev_id: dev_id).pluck(:dev_id).length
  end

end

