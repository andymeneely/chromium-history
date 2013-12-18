require_relative "verify_base"

class ForeignKeyVerify < VerifyBase

  def verify_code_reviews_and_cves_relationship
    error_count = CodeReview.where.not(cve: Cve.select("cve")).count
    get_results(error_count, "code_reviews", "cve")
  end

  def verify_dangling_comments
    no_dangling many_table: 'comments', \
                many_table_key: 'composite_patch_set_file_id', \
                one_table: 'patch_set_files',\
                one_table_key: 'composite_patch_set_file_id'
  end

  def verify_dangling_messages
    no_dangling many_table: 'messages', \
                many_table_key: 'code_review_id', \
                one_table: 'code_reviews',\
                one_table_key: 'issue'
  end

  def verify_dangling_patch_set_files
    no_dangling many_table: 'patch_set_files', \
                many_table_key: 'composite_patch_set_id', \
                one_table: 'patch_sets',\
                one_table_key: 'composite_patch_set_id'
  end

  def verify_dangling_patch_sets
    no_dangling many_table: 'patch_sets', \
                many_table_key: 'code_review_id', \
                one_table: 'code_reviews',\
                one_table_key: 'issue'
  end

  def verify_dangling_commit_files
    no_dangling many_table: 'commit_files', \
                many_table_key: 'commit_hash', \
                one_table: 'commits',\
                one_table_key: 'commit_hash'
  end

  private
  def get_results(error_count, table, foreign_column)
    if error_count == 0
      pass()
    else
      fail("#{error_count.to_s} inconsistent #{foreign_column} in the #{table} table")
    end
  end

  def no_dangling(arg={})
    query = "SELECT COUNT(*) FROM #{arg[:many_table]} LEFT OUTER JOIN #{arg[:one_table]} " \
      + "ON (#{arg[:many_table]}.#{arg[:many_table_key]} = #{arg[:one_table]}.#{arg[:one_table_key]}) " \
      + "WHERE #{arg[:many_table]}.#{arg[:many_table_key]} IS NULL"
    st = ActiveRecord::Base.connection.execute query
    if st.getvalue(0,0).to_i == 0
      pass()
    else
      fail("#{name} should not be dangling. #{st.getvalue(0,0)} dangling")
    end
  end

end
