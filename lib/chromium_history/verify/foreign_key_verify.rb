require_relative "verify_base"

class ForeignKeyVerify < VerifyBase

  def verify_code_reviews_and_cves_relationship
    error_count = CodeReview.where.not(cve: Cve.select("cve")).count
    get_results(error_count, "code_reviews", "cve")
  end
  
  def verify_comments_and_patch_set_files_relationship
    error_count = Comment.where.not(patch_set_file_id: PatchSetFile.select("id")).count
    get_results(error_count, "comments", "patch_set_file_id")
  end
  
  def verify_messages_and_code_reviews_relationship
    error_count = Message.where.not(code_review_id: CodeReview.select("id")).count
    get_results(error_count, "messages", "code_review_id")
  end
  
  def verify_patch_set_files_and_patch_sets_relationship
    error_count = PatchSetFile.where.not(patch_set_id: PatchSet.select("id")).count
    get_results(error_count, "patch_set_files", "patch_set_id")
  end
  
  def verify_patch_sets_and_code_reviews_relationship
    error_count = PatchSet.where.not(code_review_id: CodeReview.select("id")).count
    get_results(error_count, "patch_sets", "code_review_id")
  end

  private
  def get_results(error_count, table, foreign_column)
    if error_count == 0
      pass()
    else
      fail("#{error_count.to_s} inconsistent #{foreign_column} in the #{table} table")
    end
  end

  
end
