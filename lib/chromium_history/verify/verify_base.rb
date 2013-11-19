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
  
  private
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
  
end
