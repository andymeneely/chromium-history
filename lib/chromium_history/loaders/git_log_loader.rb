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
	
	@@GIT_LOG_PROPERTIES = [:commit_hash, :parent_hash, :author, :author_email, 
		:committer_name, :commiterr_email]
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
		commit_arr = Array.new
		isCommitSec = false
		isStarted = false

		file.each_line do |line|
			if line.strip.match(/^:::$/)

				#begin processing, encountered
				#first commit avoid adding 
				#any garbage before first commit
				if commit_count == 0
					isStarted = true
				else
					process_commit(commit_arr)
				end	

				#increment commit count
				commit_count+=1 

			else
				#avoid adding empty string
				#or havent started yet
				commit_arr.push(line) unless line.strip == "" or !isStarted
			end

		end

	end#get_commit


	def process_commit(arr)

		hash = Hash.new
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

		arr.clear

		ctf = transfer(Commit.new, hash ,@@GIT_LOG_PROPERTIES)

		ctf.save

	end#process_commit

end#class