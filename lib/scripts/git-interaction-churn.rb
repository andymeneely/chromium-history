#!/usr/bin/ruby

# Copyright (C) 2012 Andy Meneely
#
# Code and Interactive churn script for Git
#
# Contributors: Andy Meneely

require 'set'
require 'oj'

if ARGV.size != 2
	puts "Usage: git-interactive-churn.sh REVISION FILE"
	puts "You must be in a git repository for this to work"
	exit
end

# input is the revision hash and the file - assume it's correct
revision = ARGV[0]
file = ARGV[1]

# initialize our counts
lines_added = 0
lines_deleted = 0
lines_deleted_self = 0
lines_deleted_other = 0
author = nil
authors_affected = Set.new 

# Run blame, once for this particular file, storing as we go
# * Leading up to the revision prior to that (hence the ^) 
# * -l for showing long revision names 
blame = Hash.new
blame_text = `git blame -l #{revision}^ -- #{file}`
blame_text.each_line { | blame_line | 
        blame_line = blame_line.force_encoding("iso-8859-1")
	line_number=blame_line[/[\d]+\)/].to_i
	blame[line_number] = blame_line
}

# Determine the number of "effective authors"
effective_authors = Set.new
blame.each{ | num,blame_line |
	effective_authors << blame_line.split(/[(]/)[1].split(/[\d]{4}/)[0].chomp.strip
}

#Use git log to show only that one file at the one revision, no diff context!
patch_text = `git log -p --unified=0 -1 #{revision} -- #{file}`
patch_text.each_line { | line |
	if line.start_with? "Author: " 
		author = line[8..line.index(' <')].chomp.strip # store just the author name
	elsif line.start_with? "@@"
		#parsing the @@ -a,b +c,d @@
		lines_deleted_start = line.split(/[ ]+/)[1].split(/[,]+/)[0] #a 
		lines_deleted_num = line.split(/[ ]+/)[1].split(/[,]+/)[1] # b 
		lines_added_num = line.split(/[ ]+/)[2].split(/[,]+/)[1] #d

		#lines_deleted_start isn't ACTUALLy negative...
		lines_deleted_start = lines_deleted_start.to_i * -1

		# The _num vars are 1 if they were nil, for the ones of this format:
		# @@ -a +c @@ (which implies a 1)
		lines_deleted_num ||= 1  
		lines_added_num ||= 1 
		# ...and they need to be integers
		lines_deleted_num = lines_deleted_num.to_i
		lines_added_num = lines_added_num.to_i

		# Ok, add to the totals now
		lines_added += lines_added_num
		lines_deleted += lines_deleted_num

		# Look it up in our blame hash
		if lines_deleted_num > 0 then
			num = lines_deleted_start
			begin	
				#does the blame line have the author of this commit?
				if blame[num].include?(author) 
					lines_deleted_self+=1
				else
					lines_deleted_other+=1
					author_affected = blame[num].split(/[(]+/)[1].split(/[\d]{4}/)[0].strip
				   	authors_affected << author_affected	
				end	
				num+=1
			end until num > (lines_deleted_start + lines_deleted_num - 1)
		end
	end 
}

comm_file_churn = Hash.new

comm_file_churn['commit'] = revision
comm_file_churn['filepath'] = file
comm_file_churn['total_churn'] = lines_added + lines_deleted
comm_file_churn['lines_added'] = lines_added
comm_file_churn['lines_deleted'] = lines_deleted
comm_file_churn['lines_deleted_self'] = lines_deleted_self
comm_file_churn['lines_deleted_other'] = lines_deleted_self
comm_file_churn['num_devs_affected'] = authors_affected.size
comm_file_churn['devs_affected'] = authors_affected.to_a
comm_file_churn['num_effective_devs'] = effective_authors.size 
comm_file_churn['effective_devs'] = effective_authors.to_a
comm_file_churn['new_effective_dev'] = !effective_authors.include?(author.strip)

print Oj.dump(comm_file_churn)
