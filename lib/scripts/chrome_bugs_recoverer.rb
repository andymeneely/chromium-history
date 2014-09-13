#!/usr/bin/env ruby
require 'set'
require 'trollop'
require 'typhoeus'
require 'oj'


class GoogleCodeBugRecoverer
  
  Typhoeus::Config.verbose = false

  @@file_location = './bugs/json/'
  @@baseurl = "http://code.google.com/feeds/issues/p/chromium/issues/full?alt=json&can=all&max-results=1&id="

  def initialize()
    @bugs = Array.new
  end


  def recover_dangling
    arg = {many_table: 'bugs', \
          many_table_key: 'bug_id', \
          one_table: 'commit_bugs', \
          one_table_key: 'bug_id'}
   
    query = "SELECT #{arg[:one_table]}.#{arg[:one_table_key]} " \
    + "FROM #{arg[:many_table]} RIGHT OUTER JOIN #{arg[:one_table]} " \
    + "ON (#{arg[:many_table]}.#{arg[:many_table_key]} = #{arg[:one_table]}.#{arg[:one_table_key]}) " \
    + "WHERE #{arg[:many_table]}.#{arg[:many_table_key]} IS NULL"
   
    
    st = ActiveRecord::Base.connection.execute query
    st.each do |row|
      recover_bug(row["bug_id"])
    end
  end

  def recover_bug(bug_id)
    #Creates folder to store files.
    FileUtils.mkdir_p(@@file_location) unless File.directory?(@@file_location)
    issue_request = Typhoeus::Request.new(@@baseurl+bug_id.to_s)  # make a new request
    issue_request.on_complete do |issue_resp|
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
      @bugs << entry
      end
    end
    issue_request.run
  end

  def save_bugs()
    Oj.to_file(@@file_location + "recovered.json", @bugs)
  end
end

r = GoogleCodeBugRecoverer.new()
r.recover_dangling()
r.save_bugs
