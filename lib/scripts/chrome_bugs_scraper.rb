#!/usr/bin/env ruby
require 'set' # built-in set
require 'trollop' # command line args
require 'typhoeus' # http requests
require 'oj' # json parser

# This script gets all of the accessible data from the chromium issues feed

# Trollop options for command-line (it prints out the banner and gives you options when you run --help)
# The useful part is beiung able to set the cursor and delay when you are running the script from cmd-line
# opts creates a hash where each 'opt' is a key (ex: opt: :key, "value", defaut 1, type: Integer)
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
  # makes it so you're not getting all the connection information
  Typhoeus::Config.verbose = false 

  @@file_location = './bugs/json/'
  @@baseurl = "http://code.google.com/feeds/issues/p/chromium/issues/full?alt=json&can=all&max-results=500&start-index="

  #create variables in GoogleCodeBugScraper to be able to read/write to 
  attr_accessor :ids, :data, :patches
   
  # Return the baseurl (for accessing outside this script)
  # 
  # @return String baseurl
  def self.baseurl
    @@baseurl
  end

  # Create a new instance with command line input (if no command line input, it uses defaults)
  # @param  initial=nil Hash The initial values we have.
  # This should match the output of to_hash
  # 
  # @return GoogleCodeBugScraper Our new object
  def initialize(opts)
    @opts = opts
    @cursor = @opts[:cursor]
  end

  def get_cursor()
    return @cursor
  end

  # Gets the issues and issue replies and dumps them to a json file 
  # Uses the start index and items/page to know what data to request
  def get_data(next_link="",delay=@opts[:delay], concurrent_connections=1)
    
    # make a new concurrent run area
    hydra = Typhoeus::Hydra.new(max_concurrency: concurrent_connections) 

  
    puts "Fetching Data: #{@@baseurl+@cursor.to_s}"
    issue_request = Typhoeus::Request.new(@@baseurl+@cursor.to_s)  # make a new request for page of issues
   
    # use on_complete to handle http errors with Typhoeus
    issue_request.on_complete do |issue_resp|
      if issue_resp.success?
        
        bug_result = Oj.load(issue_resp.body) # push a Hash of the response onto our issues list
        
        #access start index and items/page
        start_index = bug_result["feed"]["openSearch$startIndex"]["$t"]
        items_per_page = bug_result["feed"]["openSearch$itemsPerPage"]["$t"]
        
        
        if items_per_page > 0 #verifies if there is any items left      
          
          #move cursor to the next issue you need to access
          @cursor = start_index + items_per_page        
          

          #Creates folder to store files unless the file_location exists
          FileUtils.mkdir_p(@@file_location) unless File.directory?(@@file_location)                    
          puts "#{start_index}- #{@cursor-1}: completed"
          puts "Processing replies..."

          # access the array of issues on the page
          bug_result["feed"]["entry"].each do |entry|
            entry_id = entry["issues$id"]["$t"]

            entry["link"].each do |link|

              if link["rel"] == "replies"
                
                #then get all the replies to the issue
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
          hydra.run #execute queued requests
          
          Oj.to_file(@@file_location + "#{start_index}-#{@cursor-1}.json", bug_result)
          sleep(delay)
        
        else # Received a non-successful http response.
          @cursor = -1
        end
      end
    end

    issue_request.run
   end
end


# driver code
s = GoogleCodeBugScraper.new(opts)

# execute get_data on the issues until you reach a non-successfull http resopnce
while s.get_cursor() != -1  do
   s.get_data
end

puts "Done."
