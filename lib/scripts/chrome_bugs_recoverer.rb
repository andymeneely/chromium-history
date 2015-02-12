#!/usr/bin/env ruby
require 'set' 
require 'trollop' #handles command line args
require 'typhoeus' #handles http requests
require 'oj'
require 'csv'

# IMPORTANT: 
#  - Before you run this file run the chrome_bugs_scraper.rb and chrome_bugs_csv_scraper.rb first and make sure they've finished
#  - If you are running this file you need to be in the production enviornment
#  - If you are running this file you also you need to run it after the new data from
#    chrome_bugs_scraper.rb and chrome_bugs_csv_scraper.rb has been parsed and added to the db.
#    This is because the script queries the database to figure out which issues need to be recovered.
class GoogleCodeBugRecoverer < ActiveRecord::Base
  
  # makes it so you're not getting all the connection information with a request
  Typhoeus::Config.verbose = false

  @@json_file_location = './bugs/json/'
  @@csv_file_location = './bugs/csv/'
  @@log_file_location = './bugs/'
 
  # base urls for getting a single issue 
  @@json_url = "http://code.google.com/feeds/issues/p/chromium/issues/full?alt=json&can=all&max-results=1&id="
  @@csv_url = "http://code.google.com/p/chromium/issues/csv?colspec=Id+Summary+Blocked+BlockedOn+Blocking+Stars+Status+Reporter+Opened+Closed+Modified&can=1&num=1&q=Id%3D"

  def initialize()
    @json_bugs = Array.new
    @csv_bugs = Array.new

    @json_file_index = 1
    @csv_file_index = 1

    @file_size = 500

    @errors = Array.new
  end

  # recovers data csv and json data for every record 
  # when there was a 'commit_bugs.bug_id' but not an equal 'bugs.bug_id'
  # and saves that data to new files marked as recovered
  def recover_dangling

    arg = {many_table: 'bugs', \
          many_table_key: 'bug_id', \
          one_table: 'commit_bugs', \
          one_table_key: 'bug_id'}
   
    # joins the 'bugs' table  and 'commit_bugs' table on the 'bug_id'
    # the right outer join insures that the data from  'commit_bugs' table is there no matter what
    # if 'commit_bugs' has a 'bug_id' that is not in the 'bugs' table 
    # then the joined table will keep the 'commit_bugs' attributes and populate the 'bugs' attributes with 'NULL's
    # but not visa versa
    #
    # We are selecting the 'commit_bugs.bug_id' when there was a 'commit_bugs.bug_id' but not a 'bugs.bug_id'  
    query = "SELECT DISTINCT #{arg[:one_table]}.#{arg[:one_table_key]} " \
    + "FROM #{arg[:many_table]} RIGHT OUTER JOIN #{arg[:one_table]} " \
    + "ON (#{arg[:many_table]}.#{arg[:many_table_key]} = #{arg[:one_table]}.#{arg[:one_table_key]}) " \
    + "WHERE #{arg[:many_table]}.#{arg[:many_table_key]} IS NULL"
    
    st = connection.execute query
    
    # for every record when there was a 'commit_bugs.bug_id' but not an equal 'bugs.bug_id'
    st.each do |row|
      
      puts " "
      puts "Working with bug #{row["bug_id"]}"
      puts "======================================="
      puts " "

      json_bug_recoverer(row["bug_id"])
      csv_bug_recoverer(row["bug_id"])

      #saves the json and csv bug data arrays every @file_size enteries
      if @json_bugs.size >= @file_size
        save_json_bugs()
      end

      if @csv_bugs.size >= @file_size
        save_csv_bugs()
      end

    end
    save_json_bugs() #save the last json file
    save_csv_bugs() #save the last csv file
    
    save_error_log()
  end
  
  # saves all entries in the error log
  def save_error_log()
    CSV.open(@@log_file_location + "error_log.csv", "w") do |csv| 
      csv << ["bug_id","file","response_code"]
      @errors.each do |error|
        csv << error
      end
    end

    puts "Error log saved to #{@@log_file_location}error_log.csv"
  end

  # takes bug id and adds the issue data to the csv_bug array
  #(from the csv page for that bug id)
  def csv_bug_recoverer(bug_id)
    #Creates folder to store files.
    FileUtils.mkdir_p(@@csv_file_location) unless File.directory?(@@csv_file_location)
    
    issue_request = Typhoeus::Request.new(@@csv_url+bug_id.to_s)  # make a new request
    
    #Use on_complete to handle http errors with Typhoeus
    issue_request.on_complete do |issue_resp|
      if issue_resp.success?
        parsedData = CSV.parse(issue_resp.body)
        if parsedData.size >= 3 #verify that the response contains rows
          @csv_bugs << parsedData[1]
        end
      else
        @errors << [bug_id,'csv',issue_resp.code]
      end
    end
    issue_request.run
  end

  # takes a bug id and adds the issue data to the json_bugs array 
  # (from the json page for that bug id)
  def json_bug_recoverer(bug_id)
    
    #Creates folder to store files.
    FileUtils.mkdir_p(@@json_file_location) unless File.directory?(@@json_file_location)

    issue_request = Typhoeus::Request.new(@@json_url+bug_id.to_s)  # make a new request
    
    # Use on_complete to handle http errors with Typhoeus
    issue_request.on_complete do |issue_resp|
      if issue_resp.success?
        bug_result = Oj.load(issue_resp.body)
        
        #access the array of issues on the page
        bug_result["feed"]["entry"].each do |entry|
          entry_id = entry["issues$id"]["$t"]
          puts "Entry #{entry_id} completed"
          
          entry["link"].each do |link|
            if link["rel"] == "replies"
              #then get all the replies for that entry
              replies_request = Typhoeus::Request.new(link["href"]+"?alt=json&max-results=500")  # make a new request
              
              replies_request.on_complete do |replies_resp|
                if replies_resp.success?   #embeds the replies in the original object.
                  entry["replies"] = Oj.load(replies_resp.body)["feed"]["entry"]
                  puts "Replies for #{entry_id} completed"
                  sleep(0.25)
                end
              end
              replies_request.run 
            end
          end 
        @json_bugs << entry #add issue data to json_bugs array
        end

      else # Received a non-successful http response.
        @errors << [bug_id,'json',issue_resp.code]
      end
    end
    issue_request.run
  end

  # saves the array of json_bug issue data to a new 'recovered_x.json' file where x is the index
  # and resets the json_bugs array
  def save_json_bugs()
    Oj.to_file(@@json_file_location + "recovered_#{@json_file_index}.json", @json_bugs)
    puts "File recovered_#{@json_file_index}.json saved"

    @json_bugs = Array.new
    @json_file_index += 1
  end

  # saves the array of csv_bug issue data to a new 'recovered_x.csv' where x is the index
  # and resets the csv_bugs array
  def save_csv_bugs()
    CSV.open(@@csv_file_location + "recovered_#{@csv_file_index}.csv", "w") do |csv|
      @csv_bugs.each do |bug|
        begin
          csv << bug
        rescue Encoding::UndefinedConversionError
          puts "Encoding::UndefinedConversionError catched!"
        end
      end
    end

    puts "File recovered_#{@csv_file_index}.csv saved"
    
    @csv_bugs = Array.new
    @csv_file_index += 1
  end
end

r = GoogleCodeBugRecoverer.new()
r.recover_dangling()
