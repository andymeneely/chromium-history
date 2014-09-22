
# A utility class that prints out our profiler stats

module ProfilerUtil

  def print_profile(file, profile)
    full_file = profile.keys.select{|k| k.end_with? file}[0]
    puts "==== Profile for #{file} ===="
    File.readlines(full_file).each_with_index do |line,num|
      sample = profile[full_file][num+1]
      printf "% 8.1fms, % 8.1fms | %s", sample[0]/1000.0,sample[1]/1000.0, line
    end#readlines
    puts "======================"
  end
  module_function :print_profile

end
