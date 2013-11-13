#!/usr/bin/env ruby
prev_hash = ""

puts "SHA1,Relative File Path"
ARGF.each_line do |line|
  line.strip
  if m = line.match(/[0-9a-f]{40}/)
    prev_hash = m
  elsif line != "\n"
  	puts "#{prev_hash},#{line}"
  end
end
