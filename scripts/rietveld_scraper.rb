#!/usr/bin/env ruby
require 'typhoeus'
require 'oj'
require 'set'
require 'msgpack'

# 
# This is a class for basic state storage and 
# collection of Rietveld-scraping methods
# 
# @author Katherine Whitlock
class RietveldScraper  
  # Set whether we want verbose debug output or not
  Typhoeus::Config.verbose = false 
  
  @@baseurl = 'https://codereview.chromium.org'

  # 
  # return the baseurl
  # 
  # @return String baseurl
  def self.baseurl
    @@baseurl
  end

  # 
  # Get one more page of search results in json format
  # (2000 ids), using the cursor as reference
  # @param  cursor=nil String The cursor to use as reference 
  # 
  # @return  Hash The response's body in a Ruby Hash
  def self.get_more_ids(cursor=nil)
    Oj.load(
      Typhoeus.get(
        @@baseurl + "/search", 
        params: {
          "closed" => "1",
          "private" => "1", 
          "commit" => "1",
          "format" => "json",
          "keys_only" => "True",
          "with_messages" => "False",
          "cursor" => "#{cursor}"
        }
      ).body  # we want the response's body
    )
  end

  # 
  # Create a new instance
  # @param  initial=nil Hash The initial values we have.
  # This should match the output of to_hash
  # 
  # @return RietveldScraper Our new object
  def initialize(initial=nil)
    @cursor = nil
    if initial
      @ids = Set.new initial['ids']
      @issues = initial['issues']
      @patches = initial['patches']
    else
      @ids = Set.new
      @issues = Array.new
      @patches = Array.new
    end
  end

  # 
  # Generate a Hash representation of the scraper state
  # 
  # @return Hash all important fields
  def to_hash
    {
      'ids'     => @ids.to_a,
      'issues'  => @issues,
      'patches' => @patches
    }
  end
  
  # 
  # Generates a String version of the scraper
  # 
  # @return String human-readable output
  def to_s
    puts @ids.first
  end


  # 
  # Generate a JSON version of the scraper state
  # 
  # @return String The JSON representation
  def to_json
    Oj.dump(self.to_hash)
  end


  # 
  # Gemerates a MessagePack representation of the scraper state
  # @param  io=nil File Takes an IOStream and outputs to there
  # 
  # @return String The MessagePack representation
  def to_msgpack(io=nil)
    if io
      io.write self.to_hash
    else
      MessagePack.pack self.to_hash
    end
  end


  # 
  # Get IDs fetches each 2000 consecutive IDs until it reaches either a non-response
  # from the server, or a match that we have.
  # 
  # @return Set The IDs we've found (a reference to our IVAR)
  def get_ids
    puts "Fetching IDs:"
    1.times do
      begin
        json = self.get_more_ids
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
    @ids
  end


  # 
  # Concurrently grabs corresponding data for each of the IDS we have.
  # @param  with_messages=true Bool whether we want messages in the response
  # 
  # @return Array The data we've grabbed (a reference to our IVAR)
  def get_data(with_messages=true)
    puts "Fetching Data:\n"
    if @ids.empty?  # let's make sure we've got some ids
      get_ids
    end

    issue_args = {
      "messages" => true  # We don't just put with_messages here. Instead, we
    } if with_messages  # protect against possibly throwing a string into the hash we pass to the request

    patch_args = {
      'comments' => true
    } if with_messages

    hydra = Typhoeus::Hydra.new  # make a new concurrent run area
    
    @ids.each do |id|  # for each of the IDs in the pool
      issue_request = Typhoeus::Request.new(baseurl + "/api/#{id}", params: issue_args)  # make a new request
      issue_request.on_complete do |resp| 
        print 'i'  # print an 'i' when an issue request finishes
        resp_hash = Oj.load(resp.body)  
        @issues << resp_hash # push a Hash of the response onto our issues list

        resp_hash['patchsets'].each do |patch|
          patch_request = Typhoeus::Request.new(baseurl + "/api/#{id}/#{patch}", params: patch_args)
          patch_request.on_complete do |patch_resp|
            print 'p'  # print an 'p' when an issue request finishes
            @patches << Oj.load(patch_resp.body)
          end
          hydra.queue patch_request
        end
      end
      hydra.queue issue_request  # and enqueue the request
    end

    # BLOCKING CALL
    hydra.run  # This runs all the requests that are queued (200 at a time)

    @issues
  end

end

# r = RietveldScraper.new( MessagePack.load(File.open("scraper.msg", "r") ))
# r.get_ids

# Saving output:
# File.open("test.msg", "w") do |file|  
#    MessagePack.pack(r, file)
# end


# puts "Latest issue: #{element}" 
# puts "Issue Id: #{element['issue']}"
# puts "Patchsets: #{element['patchsets']}"
# puts "First Patchset:" + get_json_response(baseurl + "/api/#{element['issue']}/#{element['patchsets'][0]}").to_s
