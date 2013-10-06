#!/usr/bin/env ruby
require 'typhoeus'
require 'oj'
require 'set'
require 'msgpack'
require 'highline/import'
require 'ruby-progressbar'

class Array
  def avg
    inject { |sum, el| sum + el } / size
  end

  def std_dev
    a = avg
    sum = inject(0) { |accum, i| accum + (i - a)**2 }
    Math.sqrt(sum / (size - 1)).to_f
  end
end

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
    @ids = if File.file?(@@file_location + "ids.msg") 
      MessagePack.load( File.open(@@file_location + "ids.msg") ).to_set 
    else 
      Set.new
    end
    @issues = Array.new
    @patches = Array.new
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
    File.open(@@file_location + "ids.msg", "w") { |file| MessagePack.pack(@ids.to_a, file) }
    @ids
  end


  # 
  # Concurrently grabs corresponding data for each of the IDS we have.
  # @param  with_messages=true Bool whether we want messages in the response
  # 
  # @return Array The data we've grabbed (a reference to our IVAR)
  def get_data(our_ids=nil, delay=0.5, with_messages=true)
    puts "Fetching Data:"
    if (not our_ids) and @ids.empty?  # let's make sure we've got some ids
      get_ids
      our_ids = @ids
    end

    errors = Array.new
    times = Array.new

    issue_args = {
      "messages" => true  # We don't just put with_messages here. Instead, we
    } if with_messages  # protect against possibly throwing a string into the hash we pass to the request


    hydra = Typhoeus::Hydra.new(max_concurrency: 1) # make a new concurrent run area
    progress_bar = ProgressBar.create(:title => "Patchsets", :total => our_ids.count, :format => '%a |%b>>%i| %p%% %t')


    time_then = Time.now
    our_ids.each do |id|  # for each of the IDs in the pool
      issue_request = Typhoeus::Request.new(@@baseurl + "/api/#{id}", params: issue_args)  # make a new request
      issue_request.on_complete do |resp|
        progress_bar.increment
        if resp.success?
          result = Oj.load(resp.body) # push a Hash of the response onto our issues list
          File.open(@@file_location + "#{result['issue']}.msg", "w") { |file| MessagePack.pack(result, file) }
          @issues << result['issue']
          times << Time.now - time_then
          sleep(delay)
          time_then = Time.now
        else
          errors << id
          time_then = Time.now
        end
      end
      hydra.queue issue_request  # and enqueue the request
    end

    # BLOCKING CALL
    hydra.run  # This runs all the requests that are queued

    File.open(@@file_location + "error.log", "a") { |io| errors.each { |error| io << error << "\n" } }
    puts "We have #{errors.count} errors"
    puts "Avg Time per request: #{times.avg}"
    puts "Standard Deviation of times: #{times.std_dev}"
    @issues
  end

  
  # 
  # Grab all the patchsets for the issues we've got
  # @param  with_comments=true Bool whether we want comments in the response
  # 
  # @return Array The patches we've grabbed (a reference to our IVAR)
  def get_patches(ids=nil,with_comments=true)
    puts "Fetching Patchsets:"
    if (not ids) and @issues.empty?
      get_data
      ids = @issues
    end

    patch_args = {
      'comments' => true
    } if with_comments

    hydra = Typhoeus::Hydra.new(max_concurrency: 1)
    patch_count = Array.new
    errors = Array.new
    progress_bar = nil 

    ids.each do |id|
      if File.exist?(@@file_location + "#{id}.msg")
        issue = MessagePack.load(File.open(@@file_location + "#{id}.msg"))
        patch_count << issue['patchsets'].count
        issue['patchsets'].each do |patch|
          request = Typhoeus::Request.new(@@baseurl + "/api/#{id}/#{patch}", params: patch_args, followlocation: true)
          request.on_complete do |resp|
            progress_bar.increment
            if resp.success?
              result = Oj.load(resp.body)
              if not File.directory?(@@file_location + "/#{result['issue']}")
                FileUtils.mkdir(@@file_location + "/#{result['issue']}")
              end
              File.open(@@file_location + "/#{result['issue']}/#{result['patchset']}.msg", "w") { |file| MessagePack.pack(result, file) }
              @patches << result['patchset']
              #sleep(0.5)
            else
              if errors.key? id
                errors[id] <<  patch
              else
                errors[id] = [patch]
              end
            end
          end
          hydra.queue request
        end
      end
    end

    patch_total = patch_count.inject(:+)
    progress_bar = ProgressBar.create(:title => "Patchsets", :total => patch_total, :format => '%a |%b>>%i| %p%% %t')

    hydra.run

    File.open(@@file_location + "patch_error.log", "a") { |io| io << p(errors) }
    puts "Average patch count: #{patch_count.avg}"
    puts "Standard deviation is: #{patch_count.std_dev}"
    @patches
  end

end

# r.get_ids


# puts "Latest issue: #{element}" 
# puts "Issue Id: #{element['issue']}"
# puts "Patchsets: #{element['patchsets']}"
# puts "First Patchset:" + get_json_response(baseurl + "/api/#{element['issue']}/#{element['patchsets'][0]}").to_s
