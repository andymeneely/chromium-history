#!/usr/bin/env ruby
require 'set'
require 'trollop'
require 'typhoeus'

#Trollop options for command-line
opts = Trollop::options do
  opt :setAmountDelay, "Set the amount of delay (in seconds) between get calls.", :default => 0.5
  opt :setConcurrentConnections, "Set the number of concurrent connections.", :default=> 1
end
#use opts[:setAmountDelay], etc in code when you're trying to use that value
#to test in commandline, 'ruby rietveld_scraper.rb --setAmountDelay 300'


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

    @issues = if File.exist?(@@file_location + "issues_completed.log")
      File.readlines(@@file_location + "issues_completed.log").collect { |l| l.strip.to_i }
    else
      Array.new
    end
  end

  # 
  # Concurrently grabs corresponding data for each of the IDS we have.
  # @param  with_messages=true Bool whether we want messages in the response
  # 
  # @return Array The data we've grabbed (a reference to our IVAR)
  def get_data(delay=opts[:setAmountDelay], concurrent_connections=opts[:setConcurrentConnections], with_messages_and_comments=true)
    puts "Fetching Data:"
    if @ids.empty?  # let's make sure we've got some ids
      $stderr.puts "There appear to be no IDs, exiting."
      exit(-1)
    end

    issue_args = {
      "messages" => true             # We don't just put with_messages here. Instead, we
    } if with_messages_and_comments  # protect against possibly throwing a string into the hash we pass to the request

    patch_args = {
      'comments' => true
    } if with_messages_and_comments

    hydra = Typhoeus::Hydra.new(max_concurrency: 1) # make a new concurrent run area
    progress_bar = ProgressBar.create(:title => "Patchsets", :total => our_ids.count, :format => '%a |%b>>%i| %p%% %t')


    @ids.each do |issue_id|  # for each of the IDs in the pool
      if not @issues.include? issue_id
        issue_request = Typhoeus::Request.new(@@baseurl + "/api/#{id}", params: issue_args)  # make a new request
        issue_request.on_complete do |issue_resp|
          progress_bar.increment
          if issue_resp.success?
            issue_result = Oj.load(issue_resp.body) # push a Hash of the response onto our issues list

            #Save the issue
            Oj.to_file(@@file_location + "#{id}.json", issue_result)

            issue_result['patchsets'].each do |patch_id|
              patch_request = Typhoeus::Request.new(@@baseurl + "/api/#{issue_id}/#{patch_id}", 
                                                    params: patch_args, followlocation: true)
              patch_request.on_complete do |patch_resp|
                if patch_resp.success?
                  patch_result = Oj.load(resp.body)

                  # We need to make a directory if one isn't there
                  FileUtils.mkdir(@@file_location + "/#{issue_id}") unless File.directory?(@@file_location + "/#{issue_id}")

                  # Save the patch
                  File.open(@@file_location + "/#{issue_id}/#{patch_id}.json") { |f| f.write(resp.body) }

                  # Wait some amount of time
                  sleep(delay)
                else
                   $stderr.puts "We could not fetch patch #{patch_id} for issue #{issue_id}"
                end
              end

              hydra.queue_front patch_request  # push our request onto the front of the queue
            end

            File.open(@@file_location + "issues_completed.log", "a") { |f| f << "#{issue_id}" }
            @issues << issue_id
            sleep(delay)
          else
            $stderr.puts "We could not fetch issue #{issue_id}"
          end
        end
        hydra.queue issue_request  # and enqueue the request
      end
    end

    # BLOCKING CALL
    hydra.run  # This runs all the requests that are queued

    @issues
  end
end


r = RietveldScraper.new
ids = Array.new
File.open("./random_uniq_review_ids.txt", "r") do |file|
  file.each_line do |id|
    ids << id.to_i
  end
end
r.ids = ids
r.get_data

