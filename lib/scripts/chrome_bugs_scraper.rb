#!/usr/bin/env ruby
require 'set'
require 'trollop'
require 'typhoeus'
require 'oj'

#Trollop options for command-line
opts = Trollop::options do
  version "Rietveld Scraper 1.0"
  banner <<-EOS
The Google Code Bug Scraper fetches JSON data from Google Code.

Usage:
       

ids_file.json is a JSON file containing an array of IDs to fetch

where [options] are:
EOS

  opt :delay, "Set the amount of delay (in seconds) between get calls.", default: 0.25, type: Float
end

# This is a class for basic state storage and 
# collection of Rietveld-scraping methods
# 
# @author Katherine Whitlock
# @author Danielle Neuberger
class GoogleCodeBugScraper  
  # Set whether we want verbose debug output or not
  Typhoeus::Config.verbose = false 

  @@file_location = './bugs/'
  @@baseurl = "http://code.google.com/feeds/issues/p/chromium/issues/full?alt=json&max-results=500&start-index="


  attr_accessor :ids, :data, :patches
  # 
  # return the baseurl
  # 
  # @return String baseurl
  def self.baseurl
    @@baseurl
  end

  # 
  # Create a new instance
  # @param  initial=nil Hash The initial values we have.
  # This should match the output of to_hash
  # 
  # @return RietveldScraper Our new object
  def initialize(opts)
    @opts = opts
    @cursor = 1
  end

  # 
  # Concurrently grabs corresponding data for each of the IDS we have.
  # @param  with_messages=true Bool whether we want messages in the response
  # 
  # @return Array The data we've grabbed (a reference to our IVAR)
  def get_data(next_link="",delay=@opts[:delay], concurrent_connections=1)
       
		# hydra = Typhoeus::Hydra.new(max_concurrency: concurrent_connections) # make a new concurrent run area

	
		puts "Fetching Data: #{@@baseurl+@cursor.to_s}"
		issue_request = Typhoeus::Request.new(@@baseurl+@cursor.to_s)  # make a new request
		
		issue_request.on_complete do |issue_resp|
			if issue_resp.success?
				
				bug_result = Oj.load(issue_resp.body) # push a Hash of the response onto our issues list
				
				start_index = bug_result["feed"]["openSearch$startIndex"]["$t"]
				items_per_page = bug_result["feed"]["openSearch$itemsPerPage"]["$t"]
				
				
				if items_per_page > 0 #verifies if there is any items left			
					@cursor = start_index + items_per_page				
					
					Oj.to_file(@@file_location + "#{start_index}-#{@cursor-1}.json", bug_result)
					puts "#{start_index}- #{@cursor-1}: completed"
					
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

while @cursor != -1  do
   s.get_data
end

puts "Done."
