class VerifyBase

  def run_all(results_callback)
    @results_callback = results_callback
    self.class.public_instance_methods(false).each do |verify|
      send(verify) if verify.to_s.start_with? "verify_"
    end
  end

  protected
  def return_result(verify_name, pass, fail_message="")
    result = {}
    result[:verify_name] = verify_name
    result[:pass] = pass
    result[:fail_message] = fail_message
    @results_callback.call(result)
  end
  
end
