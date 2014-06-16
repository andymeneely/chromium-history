#!/usr/bin/env ruby

puts "Moving json code reviews into subdirectories of 250 each..."
counter = 0
chunk = 0
new_chunk = true
dir = 'chunk000'

Dir["*.json"].each do |file|
  if new_chunk
    new_chunk = false
    dir = "chunk#{"%03d" % chunk}"
    `mkdir #{dir}`
  end

  `mv #{file} #{dir}`        #move the file
  `mv #{file[0..-6]} #{dir}` #move the directory

  counter+=1
  if counter>=250
    counter = 0
    chunk += 1
    new_chunk = true
  end
end
puts "Done!"
