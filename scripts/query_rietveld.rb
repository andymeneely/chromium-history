#!/usr/bin/env ruby
require 'net/http'
require 'oj'
require 'pp'
require 'set'
require 'trollop'

opts = Trollop::options do
  banner "Query various metrics from a given Chromium code review"
  opt :id, "The code review ID number, required", :type => Integer
end

Trollop::die :id, "must be a positive integer" if opts[:id].nil? || opts[:id] < 0

id = opts[:id].to_i

baseurl = 'https://codereview.chromium.org'

def get_json_response(url)
  url = URI.parse(url)
  response = Net::HTTP.start(url.host,use_ssl: true, verify_mode: OpenSSL::SSL::VERIFY_NONE) do |http|
    http.get url.request_uri
  end
  Oj.load(response.body)
end

def get_ids(cursor=nil)
  Net::HTTP::post_form(
    URI.parse("http://codereview.chromium.org/search"), 
    {
    "closed" => "1",
    "private" => "1", 
    "commit" => "1",
    "format" => "json",
    "keys_only" => "True",
    "with_messages" => "False",
    "cursor" => "#{cursor}"
  }
  )
end

def approvals(review)
  review['messages'].inject(0) {|total,msg| (msg['approval'].to_s.eql? 'true')? total+1 : total }
end

def disapprovals(review)
  review['messages'].inject(0) {|total,msg| (msg['disapproval'].to_s.eql? 'true')? total+1 : total }
end

def non_trivial_messages(review)
  review['messages'].inject(0) {|total,msg| (msg['text'].to_s.length > 20)? total+1 : total }
end

def messaging_reviewers(review)
  review['messages'].inject(Set.new) {|set,msg| set<<msg['author']}
end

review = get_json_response(baseurl + "/api/#{id}?messages=true")

puts "Approvals:\t#{approvals review}"
puts "Disapprovals:\t#{disapprovals review}"
puts "Messages >20 chars:\t#{non_trivial_messages review}"
puts "Messaging Reviewers:\t#{(messaging_reviewers review).size}"

#puts "Patchsets for #{id}: #{review['patchsets']}"
review['patchsets'].each do |p_id|
  patchset = get_json_response(baseurl + "/api/#{id}/#{p_id}/?comments=true")
  patchset['files'].each do |file|
    puts "For patch set #{p_id}, file #{file[0]}:"
    puts "\tComments > 20 chars: #{non_trivial_messages file[1]}"
    puts "\t# Commenting reviewers: #{(messaging_reviewers file[1]).size}"
  end
end

#element = data[0]
#puts "Latest issue: #{element}" 
#puts "Issue Id: #{element['issue']}"
#puts "Patchsets: #{element['patchsets']}"
#puts "First Patchset:" + get_json_response(baseurl + "/api/#{element['issue']}/#{element['patchsets'][0]}").to_s
