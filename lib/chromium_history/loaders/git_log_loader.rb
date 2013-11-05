#
# GitLogLoader class
# parses git log commit files and extracts the
# relevant information form them
# Currently a brute force approach loading chunks of the 
# file into memory. More effecient approach requires
# more reliance on regular expression processing
#
class GitLogLoader

	include DataTransfer
	
	@@GIT_LOG_PROPERTIES = [:commit_hash, :parent_commit_hash, :author_email, :author_name, 
		:committer_name, :committer_email, :message, :filepaths, :bug, :reviewers, :test, :svn_revision]
	def load
		Dir["#{Rails.configuration.datadir}/logfiles/*.txt"].each do |log|
			get_commit(File.open(log, "r"))
		end
	end

	#
	# Get each commit from the log file
	# Process each commit in the log file
	# filled with commits
	#
	# @param - file
	#
	def get_commit(file)
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
				#we already have content queued commit
				#process it before moving on
					process_commit(commit_queue)
				end	

				#increment commit count
				commit_count+=1 

			else
				#avoid adding empty string
				#or havent started yet
				commit_queue.push(line) unless line.strip == "" or !isStarted
			end

		end

	end#get_commit

	#
	# Determine the length of the message
	# since its variable length we need to
	# pre-process it and condense it
	#
	def pre_process_commit(arr, hash)
		message = ""
		end_message_index = 0

		#index 5 should be the start
		#of the message
		for i in (5..arr.size-1)
			if not arr.fetch(i).match(/^TEST/) or
				not arr.fetch(i).match(/^git-svn-id:/) or
				not arr.fetch(i).match(/^Review URL:/) or
				not arr.fetch(i).match(/^BUG/) or
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

		arr[5] = message

		#remove the multi line 
		#message since we 
		#condensed
		for i in (6..end_message_index) 
			arr.delete(i) 
		end

		#TO-DO only get the
		#part of string we need
		arr.each do |element|
			if element.match(/^TEST=/)
				hash[:test] = element

			elsif element.match(/^git-svn-id:/)
				hash[:svn_revision] = element

			elsif element.match(/^Review URL:/)
				#hash[:reviewers] = element

			elsif element.match(/^BUG=/)
				hash[:bug] = element

			elsif element.match(/^R=/)
				hash[:reviewers] = element

			end
				
		end 

		return arr

	end#pre_process_commit


	def process_commit(arr)

		hash = Hash.new

		arr = pre_process_commit(arr, hash)

		arr.each_with_index do |element,index|

			if index == 0
				#add parent hash
				hash[:commit_hash] = element

			elsif index == 1
				#add email
				hash[:commiterr_email] = element

			elsif index == 2
				#add email w/ hash
				#Do we add this?

			elsif index == 3
				#Date/Time created
				#Do we add this?

			elsif index == 4
				#add parent_commit_hash
				hash[:parent_commit_hash] = element

			elsif index == 5
				#add message
				#over multiple lines
				hash[:message] = element

			elsif index == 6
				#add BUG
				#if exists

			elsif index == 7
				#add Reviewers
				#R
			elsif index == 8 
				#add review url

			elsif index == 9
				#add svn - git revision num

			elsif index == 10
				#another hash

			elsif index == 11
				#add filepaths
			end

		end#loop

		ctf = transfer(Commit.new, hash ,@@GIT_LOG_PROPERTIES)

		ctf.save

		arr.clear

	end#process_commit

end#class