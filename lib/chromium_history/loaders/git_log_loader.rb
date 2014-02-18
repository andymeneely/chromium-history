require 'date'
require_relative 'data_transfer'

# GitLogLoader class
# parses git log commit files and extracts the
# relevant information from them
# Currently a brute force approach loading chunks of the 
# file into memory. More effecient approach requires
# more reliance on regular expression processing
#
# Based on the following git log command:
#
# git log --pretty=format:":::%n%H%n%an%n%ae%n%ad%n%P%n%s%n%b" --stat --stat-width=300 --stat-name-width=300 --ignore-space-change
#
# @author - Christopher C. Ketant
# @author - Andy Meneely
#
class GitLogLoader

  include DataTransfer

  @@GIT_LOG_PROPERTIES = [:commit_hash, :parent_commit_hash, :author_email,
                          :message, :bug, :code_review_id, :svn_revision, :created_at]

  @@GIT_LOG_FILE_PROPERTIES = [:commit_id, :filepath]

  @@BULK_IMPORT_BLOCK_SIZE=500 # The number of records we collect before we push to the db

  def load
    @commits_to_save = []
    @commit_filepaths_to_save = []
    get_commits(File.open("#{Rails.configuration.datadir}/chromium-gitlog.txt", "r"))

    Commit.import @commits_to_save #Import Whatever is left over
    CommitFilepath.import @commit_filepaths_to_save

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
    commit_count = 0
    commit_queue= Array.new
    isCommitSec = false
    isStarted = false

    file.each_line do |line|
      if line.strip.match(/^:::$/)
        #begin processing, encountered
        #first commit (:::) avoid adding 
        #any garbage before first commit
        if commit_count == 0
          isStarted = true
        else
          process_commits(commit_queue) #We already have queued the commit
        end	
        commit_count+=1 
      else
        #avoid adding empty string or havent started yet
        commit_queue.push(line) unless line.strip == "" or !isStarted
      end
    end#loop

    process_commits(commit_queue)
  end#get_commits

  #
  # Processes the commits 
  # using our processing
  # methods
  #
  # @param - Commit array
  #
  def process_commits(arr)
    commit, hash = regex_process_commit(arr)
    index_process_commit(commit, hash)
  end

  #
  # The commits have information that we 
  # can only extract information by
  # regular expression matching
  #
  #
  # @param - Array for each commit
  # @param - Hash to pass in data transfer
  #
  # @return - Array, Hash
  #
  def regex_process_commit(arr)
    message = ""
    filepaths = Array.new
    end_message_index = 0
    hash = Hash.new
    in_files = false # Have we gotten to the file portion yet? After the ;;; delimiter

    #index 5 should be the start
    #of the message
    for i in (5..arr.size-1)
      if not arr.fetch(i).match(/^git-svn-id:/) and
        not arr.fetch(i).match(/^Review URL:/) and
        not arr.fetch(i).match(/^BUG/) and
        not arr.fetch(i).match(/^R=/)

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
    for i in (6..end_message_index) 
      arr.delete(i) 
    end

    arr.each do |element|

      if element.match(/^git-svn-id:/)
        hash[:svn_revision] = element.strip.sub("git-svn-id:", "")

      elsif element.match(/^Review URL:/)
        hash[:code_review_id] = element[/(\d)+/].to_i # Greedy grab the first integer

      elsif element.match(/^BUG=/)
        hash[:bug] = element.strip.sub("BUG=", "")


      elsif element.match(/^;;;$/)
        in_files = true

      elsif in_files && element.match(/([\s-]*\|[\s-]*\d+ \+*\-*)/)
        filepaths.push(element.slice(0,element.index('|')).strip)

      end

    end 
    hash["filepaths"] = filepaths

    return arr, hash

  end#regex_process_commit

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

    arr.each_with_index do |element,index|

      if index == 0
        #add parent hash
        hash[:commit_hash] = element.strip

      elsif index == 1
        #add email
        hash[:author_email] = element.strip

      elsif index == 2
        #add email w/ hash
        #Do we add this?

      elsif index == 3
        #Date/Time created
        hash[:created_at] = DateTime.parse(element.strip)

      elsif index == 4
        #add parent_commit_hash
        hash[:parent_commit_hash] = element.strip

      end

    end#loop

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
    commit = parse_transfer(Commit.new, hash, @@GIT_LOG_PROPERTIES)
    @commits_to_save << commit #add commit to commits to be imported array
    if @commits_to_save.size > @@BULK_IMPORT_BLOCK_SIZE
      Commit.import @commits_to_save 
      @commits_to_save = []
    end

    #create the filepaths assoc w/ commit
    create_commit_filepath(hash["filepaths"], hash[:commit_hash])
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

      @commit_filepaths_to_save << CommitFilepath.new(commit_hash: commit_hash, filepath: str_path)
      if @commit_filepaths_to_save.size > @@BULK_IMPORT_BLOCK_SIZE
        CommitFilepath.import @commit_filepaths_to_save
        @commit_filepaths_to_save = []
      end

    end#loop
  end

end#class
