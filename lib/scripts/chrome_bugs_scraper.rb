#!/usr/bin/env ruby
require 'set'
require 'trollop'
require 'typhoeus'
require 'oj'

#Trollop options for command-line
opts = Trollop::options do
  version "Google Code Scraper 1.0"
  banner <<-EOS
The Google Code Bug Scraper fetches JSON data from Google Code.

Usage:
       

ids_file.json is a JSON file containing an array of IDs to fetch

where [options] are:
EOS

  opt :delay, "Set the amount of delay (in seconds) between get calls.", default: 0.25, type: Float
  opt :cursor, "Set start cursor for this run", default: 1, type: Integer
end

# @author Felivel Camilo
class GoogleCodeBugScraper  
  # Set whether we want verbose debug output or not
  Typhoeus::Config.verbose = false 

  @@file_location = './bugs/json/'
  @@baseurl = "http://code.google.com/feeds/issues/p/chromium/issues/full?alt=json&can=all&max-results=500&start-index="


  attr_accessor :ids, :data, :patches
  # 
  # return the baseurl
  # 
  # @return String baseurl
  def self.baseurl
    @@baseurl

  end

  # Create a new instance
  # @param  initial=nil Hash The initial values we have.
  # This should match the output of to_hash
  # 
  # @return GoogleCodeBugScraper  Our new object
  def initialize(opts)
    @opts = opts
    @cursor = @opts[:cursor]
  end

  def get_cursor()
    return @cursor
  end

  def get_data(next_link="",delay=@opts[:delay], concurrent_connections=1)
       
    hydra = Typhoeus::Hydra.new(max_concurrency: concurrent_connections) # make a new concurrent run area

  
    puts "Fetching Data: #{@@baseurl+@cursor.to_s}"
    issue_request = Typhoeus::Request.new(@@baseurl+@cursor.to_s)  # make a new request
    
    issue_request.on_complete do |issue_resp|
      if issue_resp.success?
        
        bug_result = Oj.load(issue_resp.body) # push a Hash of the response onto our issues list
        
        start_index = bug_result["feed"]["openSearch$startIndex"]["$t"]
        items_per_page = bug_result["feed"]["openSearch$itemsPerPage"]["$t"]
        
        
        if items_per_page > 0 #verifies if there is any items left      
          @cursor = start_index + items_per_page        
          

          #Creates folder to store files.
          FileUtils.mkdir_p(@@file_location) unless File.directory?(@@file_location)                    
          puts "#{start_index}- #{@cursor-1}: completed"
          puts "Processing replies..."

          bug_result["feed"]["entry"].each do |entry|
            entry_id = entry["issues$id"]["$t"]
            entry["link"].each do |link|
              if link["rel"] == "replies"
                replies_request = Typhoeus::Request.new(link["href"]+"?alt=json&max-results=500")  # make a new request
                replies_request.on_complete do |replies_resp|
                if replies_resp.success?
                    
                    #embeds the replies in the original object.
                    entry["replies"] = Oj.load(replies_resp.body)["feed"]["entry"]
                    puts "Replies for #{entry_id} completed"
                    sleep(delay)
                  end
                end
                hydra.queue replies_request
              end
            end    
          end
          hydra.run
          
          Oj.to_file(@@file_location + "#{start_index}-#{@cursor-1}.json", bug_result)
          sleep(delay)
        else
          @cursor = -1
        end
      end
    end

    issue_request.run
   end
end


# driver code
s = GoogleCodeBugScraper.new(opts)

while s.get_cursor() != -1  do
   s.get_data
end

puts "Done."
