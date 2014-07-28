#!/usr/bin/env ruby
require 'set'
require 'trollop'
require 'typhoeus'
require 'csv'

#Trollop options for command-line
opts = Trollop::options do
  version "Rietveld Scraper 1.0"
  banner <<-EOS
The Google Code Bug Scraper fetches CSV data from Google Code.

Usage:
       

where [options] are:
EOS

  opt :delay, "Set the amount of delay (in seconds) between get calls.", default: 0.25, type: Float
end

# This is a class for basic state storage and 
# collection of Rietveld-scraping methods
# 
# @author Felivel Camilo
class GoogleCodeBugScraperCSV  
  # Set whether we want verbose debug output or not
  Typhoeus::Config.verbose = false 

  @@file_location = './bugs/csv/'
  @@increment = 500
  #@@baseurl = "http://code.google.com/feeds/issues/p/chromium/issues/full?alt=json&max-results=500&start-index="

 
  @@baseurl = "http://code.google.com/p/chromium/issues/csv?q=&colspec=Id+Summary+Blocked+BlockedOn+Blocking+Stars+Status+Reporter+Opened+Closed+Modified&can=1&num=500&start="


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
    @total = 0
    @cursor = 1
  end

  # 
  # Concurrently grabs corresponding data for each of the IDS we have.
  # @param  with_messages=true Bool whether we want messages in the response
  # 
  # @return Array The data we've grabbed (a reference to our IVAR)
  def get_data(next_link="",delay=@opts[:delay], concurrent_connections=1)
    #hydra = Typhoeus::Hydra.new(max_concurrency: concurrent_connections) # make a new concurrent run area

  
    puts "Fetching Data: #{@@baseurl+@cursor.to_s}"
    issue_request = Typhoeus::Request.new(@@baseurl+@cursor.to_s)  # make a new request
    
    issue_request.on_complete do |issue_resp|
      if issue_resp.success?
        
        #bug_result = CSV.load(issue_resp.body) # push a Hash of the response onto our issues list
        #puts bug_result
        #CSV.to_file(@@file_location + "#{start_index}-#{@cursor-1}.json", bug_result)
        
        #extract the total number of records.
        
        parsedData = CSV.parse(issue_resp.body)
        
        if @total == 0 
          @total =  parsedData[-1][0].scan(/\d+/)[1]
        end
        
        if parsedData.size > 1 #verify that the response contains rows.

          #Writes file to disk
          file = File.new(@@file_location+@cursor.to_s+".csv", "wb")
          file.write(issue_resp.body)
          file.close

          #increments cursor
          @cursor += @@increment    

          sleep(delay)
        else
          #Exit: File fetching just headers
          @cursor = -1
        end
      else
        #Exit: Http resquest faliure.
        @cursor = -1
      end
    end

    issue_request.run
   end
end


# driver code
s = GoogleCodeBugScraperCSV.new(opts)

while (@cursor != -1)  do
   s.get_data
end

puts "Done."
