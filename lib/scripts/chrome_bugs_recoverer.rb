#!/usr/bin/env ruby
require 'set'
require 'trollop'
require 'typhoeus'
require 'oj'
require 'csv'

class GoogleCodeBugRecoverer
  
  Typhoeus::Config.verbose = false

  @@json_file_location = './bugs/json/'
  @@csv_file_location = './bugs/csv/'
  
  @@json_url = "http://code.google.com/feeds/issues/p/chromium/issues/full?alt=json&can=all&max-results=1&id="
  @@csv_url = "http://code.google.com/p/chromium/issues/csv?colspec=Id+Summary+Blocked+BlockedOn+Blocking+Stars+Status+Reporter+Opened+Closed+Modified&can=1&num=1&q=Id%3D"

  def initialize()
    @json_bugs = Array.new
    @csv_bugs = Array.new

    @json_file_index = 1
    @csv_file_index = 1

    @file_size = 500
  end


  def recover_dangling
    arg = {many_table: 'bugs', \
          many_table_key: 'bug_id', \
          one_table: 'commit_bugs', \
          one_table_key: 'bug_id'}
   
    query = "SELECT DISTINCT #{arg[:one_table]}.#{arg[:one_table_key]} " \
    + "FROM #{arg[:many_table]} RIGHT OUTER JOIN #{arg[:one_table]} " \
    + "ON (#{arg[:many_table]}.#{arg[:many_table_key]} = #{arg[:one_table]}.#{arg[:one_table_key]}) " \
    + "WHERE #{arg[:many_table]}.#{arg[:many_table_key]} IS NULL"
    
    st = ActiveRecord::Base.connection.execute query
    st.each do |row|
      
      puts " "
      puts "Working with bug #{row["bug_id"]}"
      puts "======================================="
      puts " "

      json_bug_recoverer(row["bug_id"])
      csv_bug_recoverer(row["bug_id"])

      if @json_bugs.size >= @file_size
        save_json_bugs()
      end

      if @csv_bugs.size >= @file_size
        save_csv_bugs()
      end

    end
    save_json_bugs() #save the last json file
    save_csv_bugs() #save the last csv file
  end


  def csv_bug_recoverer(bug_id)
    #Creates folder to store files.
    FileUtils.mkdir_p(@@csv_file_location) unless File.directory?(@@csv_file_location)
    
    issue_request = Typhoeus::Request.new(@@csv_url+bug_id.to_s)  # make a new request
    issue_request.on_complete do |issue_resp|
      if issue_resp.success?
        parsedData = CSV.parse(issue_resp.body)
        if parsedData.size >= 3 #verify that the response contains rows
          @csv_bugs << parsedData[1]
        end
      end
    end
    issue_request.run
  end

  def json_bug_recoverer(bug_id)
    #Creates folder to store files.
    FileUtils.mkdir_p(@@json_file_location) unless File.directory?(@@json_file_location)
    issue_request = Typhoeus::Request.new(@@json_url+bug_id.to_s)  # make a new request
    issue_request.on_complete do |issue_resp|
      if issue_resp.success?
        bug_result = Oj.load(issue_resp.body)
        bug_result["feed"]["entry"].each do |entry|
          entry_id = entry["issues$id"]["$t"]
          puts "Entry #{entry_id} completed"
          entry["link"].each do |link|
            if link["rel"] == "replies"
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
        @json_bugs << entry
        end
      end
    end
    issue_request.run
  end

  def save_json_bugs()
    Oj.to_file(@@json_file_location + "recovered_#{@json_file_index}.json", @json_bugs)
    puts "File recovered_#{@json_file_index}.json saved"

    @json_bugs = Array.new
    @json_file_index += 1
  end

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
