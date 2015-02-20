require_relative "verify_base"

class EmailVerify < VerifyBase

  def verify_no_plusses_email
    assert_equal(0, Developer.where("email like ?","%+%@%").count, "+appenders leaked into developer emails!")
  end

  def verify_no_g_tmp_emails
    assert_equal(0, Developer.find_by_sql("SELECT email FROM Developers WHERE email ~ '.*(?=@gtempaccount.com)'").count, "tmp emails found in database!")
  end


end#end of class
