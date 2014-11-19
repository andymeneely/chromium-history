#!/usr/bin/env ruby
require 'set'
require 'trollop'
require 'typhoeus'
require 'oj'

#Trollop options for command-line
opts = Trollop::options do
  version "Rietveld Scraper 1.0"
  banner <<-EOS

The Rietveld Scraper fetches JSON data from a Rietveld server (Chromium)

Files are saved in the current working directory, with directories for patchsets using the code review id

Errors are directed to stderr.

Finished downloads are stored in issues_completed.log, which is also read at the beginning to determine where to pick up.

Usage:
       test [options] <ids_file.txt>

ids_file.txt is a file containing an array of IDs to fetch (One per line)

To get file use: 
git log --pretty=format:"%n%s%n%b" --ignore-space-change | grep "^Review URL:" | grep 'codereview.chromium.org\|chromiumcodereview.appspot.com' | grep -o \[0-9]* >> ids_file.txt

where [options] are:
EOS

  opt :delay, "Set the amount of delay (in seconds) between get calls.", default: 0.25, type: Float
  opt :connections, "Set the number of concurrent connections.", default: 2, type: Integer
  opt :chunk_size, "Set the number of issues per chunk", default: 250, type: Integer
end

Trollop::die :connections, "must be greater than 1" if opts[:connections] <= 0
Trollop::die "Need to specify the filename." if ARGV.empty?

if not File.exist?(ARGV[0])
  puts "Error! File #{ARGV[0]} not found"
  exit(-1)
end

# 
# This is a class for basic state storage and 
# collection of Rietveld-scraping methods
# 
# @author Katherine Whitlock
# @author Danielle Neuberger
class RietveldScraper  
  # Set whether we want verbose debug output or not
  Typhoeus::Config.verbose = false 

  @@file_location = './'
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
  # Create a new instance
  # @param  initial=nil Hash The initial values we have.
  # This should match the output of to_hash
  # 
  # @return RietveldScraper Our new object
  def initialize(opts)
    @opts = opts
    @cursor = 0
    @chunk_temp = Array.new
    @ids = if File.exist?(ARGV[0])
      (File.readlines(ARGV[0]).collect {|l| l.strip.to_i}).to_set
    else 
      Set.new
    end
    
    @chunk_issues = Set.new
    @issues = if File.exist?(@@file_location + "issues_completed.log")
      (File.readlines(@@file_location + "issues_completed.log").collect { |l| l.strip.to_i }).to_set
    else
      Set.new
    end
  end

  # 
  # Concurrently grabs corresponding data for each of the IDS we have.
  # @param  with_messages=true Bool whether we want messages in the response
  # 
  # @return Array The data we've grabbed (a reference to our IVAR)
  def get_data(delay=@opts[:delay], concurrent_connections=@opts[:connections],chunk_size=@opts[:chunk_size], with_messages_and_comments=true)
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

    hydra = Typhoeus::Hydra.new(max_concurrency: concurrent_connections) # make a new concurrent run area


    @ids.each do |issue_id|  # for each of the IDs in the pool
      if not @issues.include? issue_id
        issue_request = Typhoeus::Request.new(@@baseurl + "/api/#{issue_id}", params: issue_args)  # make a new request
        issue_request.on_complete do |issue_resp|
          if issue_resp.success?
            oj_opts = {:symbol_keys => false, :mode => :compat}
            issue_result = Oj.load(issue_resp.body,oj_opts) # push a Hash of the response onto our issues list

            #Get the patchset data
            issue_result['patchset_data'] = {}
            issue_result['patchsets'].each do |patch_id|
              patch_request = Typhoeus::Request.new(@@baseurl + "/api/#{issue_id}/#{patch_id}", 
                                                    params: patch_args, followlocation: true)
              patch_request.on_complete do |patch_resp|
                if patch_resp.success?
                  # Add patchset to Issue 'patchset_data'
                  issue_result['patchset_data'][patch_id.to_s] = Oj.load(patch_resp.body)
                  # Wait some amount of time
                  sleep(delay)
                else
                  $stderr.puts "We could not fetch patch #{patch_id} for issue #{issue_id}"
                end
              end

              hydra.queue patch_request  # push our request onto the front of the queue
            end
            # BLOCKING CALL
            hydra.run  # This runs all the requests that are queued
 
            #Add issue to chunk temp
            @chunk_temp << issue_result
            #Add the id to chunk issue list, so we can pick up from here later.
            @chunk_issues << issue_id
            
            if @chunk_temp.size >= chunk_size
              #Save chunk to disk and reset
              Oj.to_file(@@file_location +"chunk#{"%05d" % @cursor}.json", @chunk_temp)
              puts "Saved chunk#{"%05d" % @cursor}.json"
              
              File.open(@@file_location + "issues_completed.log", "a") { |f| @chunk_issues.each {|chunk_issue_id| f << "#{chunk_issue_id}\n" }}
              @issues.merge @chunk_issues

              @chunk_temp = Array.new
              @chunk_issues = Set.new
              @cursor += 1
            end

            sleep(delay)
          
          else
            $stderr.puts "We could not fetch issue #{issue_id}"
          end
        end
        issue_request.run  # run the request
      else
        puts "Skipping #{issue_id}, already downloaded"
      end
    end

    @issues
  end
end


# driver code
r = RietveldScraper.new(opts)
r.get_data

puts "Done."
