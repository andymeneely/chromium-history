#!/usr/bin/env ruby
prev_hash = ""

ARGF.each_line do |line|
  line.strip
  if m = line.match(/[0-9a-f]{40}/)
    prev_hash = m
  elsif line != "\n" and not line.start_with?('D') # if we're not a deletion
    line = line[1..-1].strip
  	puts "#{prev_hash},#{line}"
  end
end
