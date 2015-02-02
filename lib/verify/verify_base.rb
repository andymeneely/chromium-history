class VerifyBase

  def run_all(results_callback)
    @results_callback = results_callback
    self.class.public_instance_methods(false).each do |verify|
      send(verify) if verify.to_s.start_with? "verify_"
    end
  end

  protected
  def pass()
    return_result(true)
  end
  
  def fail(fail_message="")
    return_result(false, fail_message)
  end
  
  def assert_le(exp,actual,fail_message="")
    if (exp <= actual)
      pass()
    else
      fail(<<-EOS

    Expected: <#{exp}>
    Actual:   <#{actual}>
    Message: #{fail_message} 
    In #{self.class} 
EOS
          )
    end
  end
  
  def assert_equal(exp,actual,fail_message="")
    if exp.eql? actual
      pass()
    else
      fail(<<-EOS

    Expected: <#{exp}>
    Actual:   <#{actual}>
    Message: #{fail_message} 
    In #{self.class} 
EOS
          )
    end
  end

  private
  def verify_count(name, expected, actual)
    if actual > expected
      fail("More than #{expected} #{name} found. Actual: #{actual}. See #{self.class}")
    elsif actual < expected
      fail("Less than #{expected} #{name} found. Actual: #{actual}. See #{self.class}")
    else
      pass
    end
  end

  def return_result(pass, fail_message="")
    verify_name = ""
    caller.each do |frame|
      method = frame[/`([^']*)'/, 1]
      if method.start_with? "verify_"
        verify_name = method
      end
    end
    raise 'ERROR: Verification methods must start with verify_' if verify_name.empty?
    result = {}
    result[:verify_name] = verify_name
    result[:pass] = pass
    result[:fail_message] = fail_message
    @results_callback.call(result)
  end
  
end#class
