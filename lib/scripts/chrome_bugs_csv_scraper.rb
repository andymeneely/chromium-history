#!/usr/bin/env ruby
require 'set' 
require 'trollop' #command line args handler
require 'typhoeus' # http requests
require 'csv'

#Trollop options for command-line (makes it possible to set a delay via cmd-line)
# opts creates a hash where each 'opt' is a key (ex: opt: :key, "value", defaut 1, type: Integer)
opts = Trollop::options do
  version "Google Code Scraper 1.0"
  banner <<-EOS
The Google Code Bug Scraper fetches CSV data from Google Code.

Usage:
       

where [options] are:
EOS

  opt :delay, "Set the amount of delay (in seconds) between get calls.", default: 0.25, type: Float
end

# This script gets all of the accessible data from the chromium issues csv feed 
# @author Felivel Camilo
class GoogleCodeBugScraperCSV  
  # Set whether we want verbose debug output or not (false makes it so you're not getting all the connection information)
  Typhoeus::Config.verbose = false 

  @@file_location = './bugs/csv/'
  @@increment = 500
  @@baseurl = "http://code.google.com/p/chromium/issues/csv?colspec=Id+Summary+Blocked+BlockedOn+Blocking+Stars+Status+Reporter+Opened+Closed+Modified&can=1&num=500&start="

  #create variables in GoogleCodeBugScraperCSV to be able to read/write to
  attr_accessor :ids, :data, :patches, :cursor
   
  # return the baseurl
  # 
  # @return String baseurl
  def self.baseurl
    @@baseurl
  end

  def initialize(opts)
    @opts = opts
    @total = 0
    @cursor = 1 
  end

  def get_data(next_link="",delay=@opts[:delay], concurrent_connections=1)
     
    # Creates folder to store files.
    FileUtils.mkdir_p(@@file_location) unless File.directory?(@@file_location)
      
    puts "Fetching Data: #{"Cursor: "+@cursor.to_s}"
    issue_request = Typhoeus::Request.new(@@baseurl+@cursor.to_s)  
    # make a new request
    
    # use on_complete to handle http errors with Typhoeus
    issue_request.on_complete do |issue_resp|
      if issue_resp.success?
        
        #get csv data in the issue request
        parsedData = CSV.parse(issue_resp.body)
        
        #extract the total number of records.
        if @total == 0 
          #reads the last line of the response file, 
          #and extracts the total number of records.
          @total =  parsedData[-1][0].scan(/\d+/)[1]
        end
        
        if parsedData.size > 3 #verify that the response contains rows.
          file = File.new(@@file_location+@cursor.to_s+".csv", "wb")
          file.write(issue_resp.body)
          file.close
          @cursor += @@increment    
          sleep(delay)
        else
          @cursor = -1 #Exit: File fetching just headers
          sleep(delay)
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

# execute get_data on the issues until you reach a non-successfull http resopnce
while s.cursor != -1  do
  s.get_data
end

puts "Done."
