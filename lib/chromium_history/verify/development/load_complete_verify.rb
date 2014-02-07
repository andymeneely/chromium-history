require_relative "../verify_base"

class LoadCompleteVerify < VerifyBase

  def verify_number_of_code_reviews
    verify_count("Code Reviews", 6, CodeReview.count)
  end

  def verify_number_of_patchsets
    verify_count("Patch Sets", 18, PatchSet.count)
  end

  def verify_number_of_comments
    verify_count("Comments", 14, Comment.count)
  end

  def verify_number_of_commits
    verify_count("Commits", 7, Commit.count)
  end

  def verify_number_of_messages
    verify_count("Messages", 75, Message.count)
  end

  def verify_number_of_patch_set_files
    verify_count("Patch Set Files", 72, PatchSetFile.count)
  end

  def verify_code_review_10854242_has_23_messages
    helper_count_messages(10854242, 23)
  end

  def verify_code_review_10854242_has_4_patchsets
    verify_count("Patchsets", 4, CodeReview.find_by_issue(10854242).patch_sets.count)
  end

  def verify_code_review_10854242_patchset_17001_has_3_files
    verify_count("Patch Set Files", 3, CodeReview.find_by_issue(10854242).patch_sets.find_by_patchset(17001).files.count)
  end

  def verify_code_review_10854242_last_comment
    verify_count("Comments", 2, PatchSetFile.find_by_composite_patch_set_file_id('10854242-6006-content/browser/renderer_host/backing_store_gtk.cc').comments.count)
  end

  def verify_code_review_10854242_last_comment_associations
    verify_count("Comments", 2, CodeReview.find_by_issue(10854242).patch_sets.find_by_patchset(6006).files.where(filepath: 'content/browser/renderer_host/backing_store_gtk.cc').first.comments.count)
  end

  def verify_code_review_23444043_has_16_messages
    helper_count_messages(23444043, 16)
  end

  def verify_code_review_5754053585797120_has_9_messages
    helper_count_messages(5754053585797120, 9)
  end

  def verify_code_review_9141024_has_2_messages
    helper_count_messages(9141024, 2)
  end

  def verify_code_review_9141024_was_loaded
    helper_code_review_was_loaded(9141024)
  end

  def verify_code_review_10854242_was_loaded
    helper_code_review_was_loaded(10854242)
  end

  def verify_code_review_23444043_was_loaded
    helper_code_review_was_loaded(23444043)
  end

  def verify_code_review_5754053585797120_was_loaded
    helper_code_review_was_loaded(5754053585797120)
  end

  def verify_commit_6eebdee7_has_7_files
    verify_count("Commit 6eebdee7851c52b1f481fca1cdffcbc51c8ec061",7, Commit.find_by_commit_hash("6eebdee7851c52b1f481fca1cdffcbc51c8ec061").commit_files.count)
  end
  
  def verify_commit_14df51bb_has_1_file
    verify_count('Commit 14df51bb5a7ce0e5a8ecb12b24d845d9b4ae0318', 1, Commit.find_by_commit_hash('14df51bb5a7ce0e5a8ecb12b24d845d9b4ae0318').commit_files.count)
  end

  def verify_6eebdee_has_one_review
    commit = Commit.find_by_commit_hash('6eebdee7851c52b1f481fca1cdffcbc51c8ec061')
    code_review = commit.code_review
    if(code_review.issue.eql? 5831706594508800)
      pass()
    else
      fail('Commit should have had a reviewnqq:') 
    end
  end

  private
  def helper_code_review_was_loaded(issue)
    count = CodeReview.where(issue: issue).count
    if count > 1
      fail("Code review #{issue} is duplicate.")
    elsif count < 1
      fail("Code review #{issue} not found.")
    else
      pass()
    end
  end

  def helper_count_messages(code_review, expected)
    count = CodeReview.where(issue: code_review).first.messages.count
    if count > expected
      fail("More than #{expected} messages found. Actual: #{count}")
    elsif count < expected
      fail("Less than #{expected} messages found. Actual: #{count}")
    end
  end

  def helper_check_file_path(regex, message)
    #trying to display the commit that belongs to on fail
    #but the commit id not being saved to commit_file
    count = 0

    # Get all the commit_files by the filepath column value
    files = CommitFile.pluck(:filepath)
    rgx = Regexp.new(regex)

    files.each do |path| 
      if path.match(rgx)
        count+=1
      end

    end#end each
    verify_count(message, 0, count)

  end #end verify_file_path

end#end of class
