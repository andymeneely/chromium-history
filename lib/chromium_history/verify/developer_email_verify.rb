require_relative "verify_base"

class DeveloperEmailVerify < VerifyBase

  def verify_no_plusses_email
    assert_equal(0, Developer.where("email like ?","%+%@%").count, "+appenders leaked into developer emails!")
  end

end#end of class
