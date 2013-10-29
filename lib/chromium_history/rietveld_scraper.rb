#!/usr/bin/env ruby
require 'set'
require 'trollop'
require 'typhoeus'

# 
# This is a class for basic state storage and 
# collection of Rietveld-scraping methods
# 
# @author Katherine Whitlock
class RietveldScraper  
  # Set whether we want verbose debug output or not
  Typhoeus::Config.verbose = false 

  @@file_location = '../../data/scrapes/'
  @@baseurl = 'https://codereview.chromium.org'


  attr_accessor :ids, :data, :patches
  # 
  # return the baseurl
  # 
  # @return String baseurl
  def self.baseurl
    @@baseurl
  end


#Trollop options for command-line
opts = Trollop::options do
  opt :setAmountDelay, "Set the amount of delay (in seconds) between get calls.", :default => 0.5
  opt :setConcurrentConnections, "Set the number of concurrent connections.", :default=> 1
end
p opts
#use opts[:setAmountDelay], etc in code when you're trying to use that value
#to test in commandline, 'ruby rietveld_scraper.rb --setAmountDelay 300'


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
  def initialize
    @cursor = nil
    @ids = if File.exist?(@@file_location + "ids.json") 
      Oj.load_file(@@file_location + "ids.json").to_set 
    else 
      Set.new
    end

    @issues = if condition
      File.readlines(@@file_location + "issues_completed.log").collect { |l| l.strip.to_i }
    else
      Array.new
    end

    @patches = if File.exist? @@file_location + "patches_completed.log"
      t = {}
      CSV.foreach(@@file_location + "patches_completed.log", headers: true, header_converters: :symbol, converters: :all) do |row| 
        if t.has_key?(r.fields[0])
          t[r.fields[0]] << r.fields[1] 
        else 
          t[r.fields[0]] = [r.fields[1]] 
        end 
      end
      t
    else
      {}
    end
  end

  # 
  # Get IDs fetches each 2000 consecutive IDs until it reaches either a non-response
  # from the server, or a match that we have.
  # 
  # @return Set The IDs we've found (a reference to our IVAR)
  def get_ids
    puts "Fetching IDs:"
    catch(:stale) do
      while true
        json = RietveldScraper.get_more_ids @cursor
        @cursor = json['cursor']  # Grab the cursor from the response
        new_ids = json['results']  # Grab the array of new ids from the response
        break if new_ids.empty?
        new_ids.each do |id|  # For each of the new ids we've fetched...
          if @ids.include? id  # Check if what we have is already in our Set
            puts "We're fetching stale ids. Stopping."
            throw :stale
          else  # If it's not, let's push it on
            @ids << id 
          end
        end
        print '.'  # A way to tell how many responses we've dealt with
      end
    end

    Oj.to_file(@@file_location + "ids.json", @ids.to_a)

    @ids
  end


  # 
  # Concurrently grabs corresponding data for each of the IDS we have.
  # @param  with_messages=true Bool whether we want messages in the response
  # 
  # @return Array The data we've grabbed (a reference to our IVAR)
  def get_data(our_ids=nil, delay=opts[:setAmountDelay], with_messages_and_comments=true)
    puts "Fetching Data:"
    if (not our_ids) and @ids.empty?  # let's make sure we've got some ids
      get_ids
      our_ids = @ids
    end

    errors = Array.new

    issue_args = {
      "messages" => true             # We don't just put with_messages here. Instead, we
    } if with_messages_and_comments  # protect against possibly throwing a string into the hash we pass to the request

    patch_args = {
      'comments' => true
    } if with_messages_and_comments


    patches_error_log = if File.exists? @@file_location + "patch_error.log"
      f = File.open(@@file_location + "patch_error.log", "a") 
      f << "ID, Failed_Patch"
    else
      File.open(@@file_location + "patch_error.log", "a")
    end

    issue_error_log = if File.exists? @@file_location + "issue_error.log"
      f = File.open(@@file_location + "issue_error.log", "a") 
      f << "ID"
    else
      File.open(@@file_location + "issue_error.log", "a")
    end

    issues_completed_log = File.open(@@file_location + "issues_completed.log", "a")

    patches_completed_log = if File.exist? @@file_location + "patches_completed.log"
      File.open(@@file_location + "patches_completed.log", "a") 
    else
      f = File.open(@@file_location + "patches_completed.log", "a") 
      f << "Issue, Patch"
    end


    hydra = Typhoeus::Hydra.new(max_concurrency: opts[:setConcurrentConnections]) # make a new concurrent run area
    # TODO: Fix progress bar
    #progress_bar = ProgressBar.create(:title => "Patchsets", :total => our_ids.count, :format => '%a |%b>>%i| %p%% %t')


    our_ids.each do |issue_id|  # for each of the IDs in the pool
      if not @issues.include? issue_id
        issue_request = Typhoeus::Request.new(@@baseurl + "/api/#{id}", params: issue_args)  # make a new request
        issue_request.on_complete do |issue_resp|
          #progress_bar.increment
          if issue_resp.success?
            issue_result = Oj.load(issue_resp.body) # push a Hash of the response onto our issues list

            #Save the issue
            Oj.to_file(@@file_location + "#{id}.json", issue_result)

            issue_result['patchsets'].each do |patch_id|
              if @patches[issue_id] and not @patches[issue_id].include?(patch_id)
                patch_request = Typhoeus::Request.new(@@baseurl + "/api/#{issue_id}/#{patch_id}", 
                                                      params: patch_args, followlocation: true)
                patch_request.on_complete do |patch_resp|
                  if patch_resp.success?
                    patch_result = Oj.load(resp.body)

                    # We need to make a directory if one isn't there
                    FileUtils.mkdir(@@file_location + "/#{issue_id}") unless File.directory?(@@file_location + "/#{issue_id}")

                    # Save the patch
                    Oj.to_file(@@file_location + "/#{issue_id}/#{patch_id}.json", patch_result)
                    patches_completed_log << "#{issue_id}, #{patch_id}"

                    if @patches.has_key?(r.fields[0])
                      @patches[id] << patch 
                    else 
                      @patches[id] = [patch] 
                    end 

                    # Wait some amount of time
                    sleep(delay)
                  else
                    patches_error_log << "#{issue_id}, #{patch_id}"
                  end
                end
                hydra.queue_front patch_request
              end
            end
            issues_completed_log << "#{issue_id}"
            @issues << issue_id
            sleep(delay)
          else
            issue_error_log << issue_id
          end
        end
        hydra.queue issue_request  # and enqueue the request
      end
    end

    # BLOCKING CALL
    hydra.run  # This runs all the requests that are queued

    File.open(@@file_location + "issue_error.log", "a") { |io| errors.each { |error| io << error << "\n" } }
    puts "We have #{errors.count} errors"
    @issues
  end
end