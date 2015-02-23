require 'date'
require 'set'
require_relative 'data_transfer'
require 'profiler_util'

# GitLogLoader class
# parses git log commit files and extracts the
# relevant information from them
# Currently a brute force approach loading chunks of the 
# file into memory. More effecient approach requires
# more reliance on regular expression processing
#
# Based on the following git log command:
#
# git log --pretty=format:":::%n%H%n%an%n%ae%n%ad%n%P%n%s%n%b;;;" --stat --stat-width=300 --stat-name-width=300 --ignore-space-change
# @author - Christopher C. Ketant
# @author - Andy Meneely
#
class GitLogLoader

  include DataTransfer
  include ProfilerUtil

  @@GIT_LOG_BUG_PROPERTIES = [:commit_hash, :bug_id]
  @@GIT_LOG_FILE_PROPERTIES = [:commit_hash, :filepath]
  @@GIT_LOG_PROPERTIES = [:commit_hash, :parent_commit_hash, :author_email,:author_id, :bug, :created_at, :message]

  def load
    @reviews_to_update = []
    @con = ActiveRecord::Base.connection.raw_connection
    
    # create prepared insert statments because we will be using them many times
    # the insert statments will insert the values for each git log property into the db every time it is executed
    @con.prepare('commitInsert', "INSERT INTO commits (#{@@GIT_LOG_PROPERTIES.map{|key| key.to_s}.join(', ')}) VALUES ($1, $2, $3, $4, $5, $6, $7)")
    @con.prepare('fileInsert', "INSERT INTO commit_filepaths (#{@@GIT_LOG_FILE_PROPERTIES.map{|key| key.to_s}.join(', ')}) VALUES ($1, $2)")
    @con.prepare('bugInsert', "INSERT INTO commit_bugs (#{@@GIT_LOG_BUG_PROPERTIES.map{|key| key.to_s}.join(', ')}) VALUES ($1, $2)")
    get_commits(File.open("#{Rails.configuration.datadir}/chromium-gitlog.txt", "r"))

    #update each code review you can find in the git log with its hash
    @reviews_to_update.each do |id,hash|
      rev = CodeReview.find_by(issue: id)
      unless rev.nil?
        rev.update_attribute(:commit_hash, hash)
      end
    end
  end

  #
  # Get each commit from the log file
  # individually which are separated by
  # ":::" then process each commit 
  # in the log file
  #
  # @param - file
  #
  def get_commits(file)
    commit_queue= Array.new
    isCommitSec = false
    isStarted = false

    file.each_line do |line|
      if line.strip =~ (/^:::$/) or line.strip =~ (/^;;;:::$/)
        #begin processing, encountered
        #first commit (:::) avoid adding 
        #any garbage before first commit
        if not isStarted
          isStarted = true
        else
          # Process commits, we already have queued the commit
          commit, hash = regex_process_commit(commit_queue)
          index_process_commit(commit, hash)
        end

      else
        #avoid adding empty string or havent started yet
        commit_queue.push(line) unless line.strip == "" or not isStarted
      end
    end#loop

    #process commits
    commit, hash = regex_process_commit(commit_queue)
    index_process_commit(commit, hash)

  end#get_commits

  #
  # The commits have information that we 
  # can only extract information by
  # regular expression matching
  #
  #
  # @param - Array for each commit
  #
  # @return - Array, Hash to pass into data transfer
  #
  def regex_process_commit(arr)
    message = ""
    filepaths = Array.new
    end_message_index = 0
    hash = Hash.new
    in_files = false # Have we gotten to the file portion yet? After the ;;; delimiter

    #index 5 should be the start
    #of the message
    (5..arr.size-1).each do |i|
      #add lines to message string if they are not identifers of lines we want to get later
      if not arr.fetch(i) =~ (/^git-svn-id:/) and
        not arr.fetch(i) =~ (/^Review URL:/) and
        not arr.fetch(i) =~ (/^BUG/) and
        not arr.fetch(i) =~ (/^R=/)

        #concat the message into 1
        #string
        message = message + " " + arr.fetch(i)
      else
        #get the last index of the 
        #message, is it multiple
        #lines
        end_message_index = i
        break
      end
    end

    hash[:message] = message
    arr[5] = message

    #remove the multi line message since we condensed it
    (6..end_message_index).each do |i| 
      arr.delete(i) 
    end

    arr.each do |element|
      if fast_match(element, /^Review URL:/)
        @reviews_to_update[element[/(\d)+/].to_i] = arr[0].strip

      elsif fast_match(element, /^BUG=/)
        hash[:bug] = element.strip.sub("BUG=", "")

      elsif fast_match(element, /^;;;/)
        in_files = true

      elsif in_files and element.include?('|')  # stats output needs to have a pipe
        # get the filepath and push it into the filepaths array
        filepaths.push(element.slice(0,element.index('|')).strip)

      end#if

    end#arr.each
    hash["filepaths"] = filepaths

    return arr, hash

  end#regex_process_commit

  def fast_match(str, pattern)
    return not((str =~ pattern).nil?)
  end

  #
  # Process each of the commit
  # by sequentially going through
  # by index and inserting in 
  # to hash
  #
  # @param- Array of commit
  # @param- Hash 
  #
  def index_process_commit(arr, hash)

    commit_hash_str = arr[0].strip
    author_email_str = arr[1].strip
    created_at_tstamp = DateTime.parse(arr[3].strip)
    parent_hash = arr[4].strip

    #add commit hash
    hash[:commit_hash] = commit_hash_str[0..254]
    puts "WARNING! Hash too long #{commit_hash_str}" if commit_hash_str.length > 254

    #add email
    hash[:author_email] = author_email_str[0..254]
    puts "WARNING! Email too long #{author_email_str}" if author_email_str.length > 254
    
    #add author id 
    dev = Developer.search_or_add author_email_str
    if dev.nil?
      unless %w(initial.commit).include? author_email_str
        puts "WARNING! Email invalid for #{author_email_str}"
      end
    else
      hash[:author_id] = dev.id 
    end

    #add Date/Time created
    hash[:created_at] = created_at_tstamp

    #add parent_commit_hash
    hash[:parent_commit_hash] = parent_hash[0..254]
    puts "WARNING! Parent hash too long #{parent_hash}" if parent_hash.length > 254

    add_commit_to_db(hash)

    arr.clear

  end#process_commit

  #
  # After the commits are 
  # processed and structured
  # in hash then save to db
  #
  # @param- Hash
  #
  def add_commit_to_db(hash)
    #insert hash values into proper attribute in commits table
    @con.exec_prepared('commitInsert', hash.values_at(*@@GIT_LOG_PROPERTIES))
    
    create_commit_filepath(hash["filepaths"], hash[:commit_hash])
    create_commit_bug(hash[:bug], hash[:commit_hash]) if hash[:bug]!=nil
  end#add_commit_to_db

  #
  # Adding the Filepath Model
  # Filepath to the files associated
  # with the commit
  #
  # Checks if filepath already exists
  # @param- Array of file paths
  #
  def create_commit_filepath(filepaths, commit_hash)
    filepaths.each do |str_path|
      @con.exec_prepared('fileInsert', [commit_hash,str_path])
    end
  end

  #
  # Adding the Bug Model
  # Bugs associated
  # with the commit
  #
  # @param- string bugs
  def create_commit_bug(bugs, commit_hash)
    # split the bugs by comma and any space char.
    bugs = bugs.split(%r{,\s*})
    bugs_set = Set.new

    bugs.each do |bug|

      # Normalize bug field
      bug.downcase!
      bug.strip!

      # Remove the common bad text
      bad_text = ["chromium:","issue","bug=","="]
      bad_text.each do |text|
        bug.slice! text if bug.start_with? text
      end

      # If the bug is a number with 6 digits
      if fast_match(bug,/^(\s*\d{1,6}\s*)$/)
        bugs_set << bug.to_i
        # If it is a repetition of 4-6 digits
      elsif fast_match(bug,/([0-9]{4,6})\1/)
        bug = /([0-9]{4,6})\1/.match(bug)[1]
        bugs_set << bug.to_i
      end
    end

    bugs_set.each do |bug|
      @con.exec_prepared('bugInsert', [commit_hash,bug])
    end
  end
end#class
