#!/usr/bin/env ruby
require 'net/http'
require 'oj'
require 'pp'
require 'set'

baseurl = 'https://codereview.chromium.org'

def get_json_response(url)
  Oj.load(Net::HTTP::get(URI.parse(url)))
end

def get_ids(cursor=nil)
  Net::HTTP::post_form( 
    URI.parse("https://codereview.chromium.org/search"), 
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

cursor = nil
ids = Set.new()

1.times do
  p '.'
  response = get_ids(cursor)
  json = Oj.load(response.body)
  cursor = json['cursor']
  new_ids = json['results']
  new_ids.each { |id| ids << id }
  # ids.collect do |id|
  # #   Oj.load(Net::HTTP::get(URI.parse "https://codereview.chromium.org/api/#{id}"))
  # end
end

p ids

data = ids.to_a[0..5].collect do |id|
  p '.'
  get_json_response(baseurl + "/api/#{id}")
end

# f =File.open('data.txt', 'w') 
# f << data

element = data[0]
puts "Latest issue: #{element}" 
puts "Issue Id: #{element['issue']}"
puts "Patchsets: #{element['patchsets']}"
puts "First Patchset:" + get_json_response(baseurl + "/api/#{element['issue']}/#{element['patchsets'][0]}").to_s
