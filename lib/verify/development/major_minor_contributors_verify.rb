require_relative '../verify_base'

class MajorMinorContributorsVerify < VerifyBase
  # commits.author_id's ^, (ID of Developer)
  # 23=>1, 22=>4, 33=>10, 7=>1 | total=>16
  # assert_equal [1], dev.participants.where('issue = 52823002').pluck('security_adjacencys')

  # fails because reasons
  def verify_contributor_major_and_minor
    # fp = 'ui/views/widget/desktop_aura/desktop_root_window_host_x11.cc'
    fp = 'ui/gfx/canvas_skia.cc'
    file = ReleaseFilepath.find_by(thefilepath: fp)
    assert_equal 1, file.num_major_contributors
    assert_equal 1, file.num_minor_contributors
  end

end#class