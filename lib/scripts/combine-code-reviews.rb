#!/usr/bin/env ruby

require 'oj'

puts "Combining Code review directories into single JSON files"

oj_opts = {:symbol_keys => false, :mode => :compat}

Dir['chunk*'].each do |dir|
  array = []
  Dir.chdir(dir) do
    Dir['*.json'].each do |review_file|
      txt = ''
      review_json = Oj.load_file(review_file, oj_opts)
      review_json['patchset_data'] = {}
      review_json['patchsets'].each do |pid|
        patchset_file = "#{review_file.gsub(/\.json$/,'')}/#{pid}.json" #e.g. 10854242/1001.json
        review_json['patchset_data'][pid.to_i] = Oj.load_file(patchset_file)
      end
      array << review_json
    end
  end
  File.open("#{dir}.json", 'w+') do |f|
    f.write(Oj.dump(array, oj_opts))
  end
end

puts "Done!"

