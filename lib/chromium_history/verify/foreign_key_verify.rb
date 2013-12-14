require_relative "verify_base"

class ForeignKeyVerify < VerifyBase

  def verify_code_reviews_and_cves_relationship
    error_count = CodeReview.where.not(cve: Cve.select("cve")).count
    get_results(error_count, "code_reviews", "cve")
  end

  def verify_comments_and_patch_set_files_relationship
    no_dangling 'Comments',<<eos
      SELECT COUNT(*) FROM 
        (comments c LEFT OUTER JOIN patch_set_files psf
          ON (c.composite_patch_set_file_id=psf.composite_patch_set_file_id)
        )
      WHERE c.composite_patch_set_file_id IS NULL;
eos
  end

  def verify_messages_and_code_reviews_relationship
    error_count = Message.where.not(code_review_id: CodeReview.select("issue")).count
    get_results(error_count, "messages", "code_review_id")
  end

  def verify_patch_set_files_and_patch_sets_relationship
    error_count = PatchSetFile.where.not(patch_set_id: PatchSet.select("id")).count
    get_results(error_count, "patch_set_files", "patch_set_id")
  end

  def verify_patch_sets_and_code_reviews_relationship
    error_count = PatchSet.where.not(code_review_id: CodeReview.select("issue")).count
    get_results(error_count, "patch_sets", "code_review_id")
  end

  def verify_commit_files_all_have_commits
    error_count = CommitFile.where.not(commit_hash: Commit.select("commit_hash")).count
    get_results(error_count, "commit files", "commit_hash")
  end

  private
  def get_results(error_count, table, foreign_column)
    if error_count == 0
      pass()
    else
      fail("#{error_count.to_s} inconsistent #{foreign_column} in the #{table} table")
    end
  end

  def no_dangling(name, query)
    st = ActiveRecord::Base.connection.execute query
    if st.getvalue(0,0).to_i == 0
      pass()
    else
      fail("#{name} should not be dangling. #{st.getvalue(0,0)} dangling")
    end
  end

end
