#!/usr/bin/env ruby
require 'set'
require 'trollop'
require 'typhoeus'
require 'oj'

#Trollop options for command-line
opts = Trollop::options do
  version "Get Rietveld IDs"
  banner <<-EOS

This script fetches the code review IDs from the Chromium project. 

IDs are printed to stdout.

Errors are directed to stderr.

  EOS

  opt :delay, "Set the amount of delay (in seconds) between get calls.", default: 0.25, type: Float
  opt :connections, "Set the number of concurrent connections.", default: 2, type: Integer
end

Trollop::die :connections, "must be greater than 1" if opts[:connections] <= 0

# 
# This is a class for basic state storage and 
# collection of Rietveld-scraping methods
# 
# @author Andy Meneely
class GetCodeReviewIDs  
  # Set whether we want verbose debug output or not
  Typhoeus::Config.verbose = false 

  @@file_location = './'
  @@baseurl = 'https://codereview.chromium.org'

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
  end

  def run(delay=@opts[:delay], concurrent_connections=@opts[:connections])
    params = {:format => 'json', :keys_only => true, :cursor => nil}
    (1..400).each do |i|
      request = Typhoeus::Request.new(@@baseurl + '/search', params: params)
      request.on_complete do |response|
        hash = Oj.load(response.body)
        ids = hash['results']
        ids.each {|id| puts id}
        params[:cursor] = hash['cursor']
      end
      request.run
    end
  end
end
# driver code
GetCodeReviewIDs.new(opts).run

puts "Done."
