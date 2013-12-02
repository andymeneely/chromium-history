require_relative "../verify_base"

class LoadCompleteVerify < VerifyBase

  def verify_exactly_4_code_reviews_exist
    verify_count("Code Reviews", 5, CodeReview.count)
  end

  def verify_exactly_12_patch_sets_exist
    verify_count("Patch Sets", 16, PatchSet.count)
  end

  def verify_exactly_9_comments_exist
    verify_count("Comments", 14, Comment.count)
  end

  def verify_commit_count
    verify_count("Commits", 6, Commit.count)
  end

  def verify_code_review_10854242_has_23_messages
    helper_count_messages(10854242, 23)
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

  def verify_commit_files_have_no_ellipses
    helper_check_file_path('\.{2,}', "File Paths with Ellipses")
  end

  def verify_commit_files_have_no_spaces
    helper_check_file_path('\s', "File Paths with Spaces")
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
      fail("More than #{expected} messages found.")
    elsif count < expected
      fail("Less than #{expected} messages found.")
    end
  end

  def verify_count(name, expected, actual)
    if actual > expected
      fail("More than #{expected} #{name} found. Actual: #{actual}")
    elsif actual < expected
      fail("Less than #{expected} #{name} found. Actual: #{actual}")
    else
      pass()
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
