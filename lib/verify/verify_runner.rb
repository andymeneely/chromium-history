# Require all verification scripts that are outside the environment directories
Dir["#{File.dirname(__FILE__)}/*.rb"].each do |filename|
  require filename if filename.to_s.ends_with? "_verify.rb"
end
# Require environment specific verification scripts
Dir["#{File.dirname(__FILE__)}/#{Rails.env}/*.rb"].each do |filename|
  require filename if filename.to_s.ends_with? "_verify.rb"
end

class VerifyRunner
  def self.run_all
    puts "\nExecuting Verify.\n\n"
    @@pass = 0
    @@fail = 0
    run_verify "."
    run_verify Rails.env
    num_pass = "#{@@pass} passed."
    num_fail = "#{@@fail} failed."
    puts "\n\nVerify completed. #{num_pass.green} #{num_fail.red}\n"
  end
  
  private
  def self.print_results(result_data)
    if result_data[:pass]
      print('.')
      @@pass += 1
    else
      result = "\n[#{"FAIL".red}] #{result_data[:fail_message]}"
      printf "  %-60s %s\n", result_data[:verify_name], result
      @@fail += 1
    end

  end

  def self.run_verify(path)
    Dir["#{File.dirname(__FILE__)}/#{path}/*.rb"].each do |filename|
      klass = File.basename(filename, '.rb').camelize.constantize
      next unless klass.ancestors.include?(VerifyBase)
      klass.new.run_all method(:print_results)
    end
  end
end
