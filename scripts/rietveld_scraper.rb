#!/usr/bin/env ruby
require 'net/http'
require 'oj'
require 'set'
require 'msgpack'

class RietveldScraper
  attr_accessor :ids

  @@baseurl = 'https://codereview.chromium.org'

  def self.get_json_response(url, args=nil)
    Oj.load(Net::HTTP::get(URI.parse(url, args)))
  end

  def self.get_more_ids(cursor=nil)
    Net::HTTP::post_form( 
      URI.parse(@@baseurl + "/search"), 
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

  def initialize
    @cursor = nil
    @ids = Set.new
    @issues = Array.new
    @patches = Array.new
  end

  def to_hash
    {
      cursor:  @cursor,
      ids:     @ids.to_a,
      issues:  @issues,
      patches: @patches
    }
  end
  
  def to_s
    puts @ids.first
  end

  def to_json
    Oj.dump(self.to_hash)
  end

  def to_msgpack(io=nil)
    if io
      io.write self.to_hash
    else
      MessagePack.pack self.to_hash
    end
  end

  def get_ids
    puts "Fetching IDs:"
    while true
      begin
        json = Oj.load(self.get_more_ids(@cursor).body)
        @cursor = json['cursor']  # Grab the cursor from the response
        new_ids = json['results']  # Grab the array of new ids from the response
        new_ids.each do |id|  # For each of the new ids we've fetched...
          if ids.include? id  # Check if what we have is already in our Set
            puts "We're fetching stale ids. Stopping."
            break
          else  # If it's not, let's push it on
            @ids << id 
          end
        end
        print '.'  # A way to tell how many responses we've dealt with
      rescue
        puts "Reached end of results"
      end
    end
  end

  def get_data
    puts "Fetching Data:\n"
    if not @ids  # let's make sure we've got some ids
      get_ids
    end

    ids.map do |id|
      print '.'
      @issues << self.get_json_response(baseurl + "/api/#{id}", {
        "messages" => true
        })
    end
  end

end

# puts "Latest issue: #{element}" 
# puts "Issue Id: #{element['issue']}"
# puts "Patchsets: #{element['patchsets']}"
# puts "First Patchset:" + get_json_response(baseurl + "/api/#{element['issue']}/#{element['patchsets'][0]}").to_s
