require_relative "verify_base"

class FilepathVulnerableVerify < verify_base

	#If a Filepath has ever been involved in a code review that inspected
	# a vulnerability, then this should return true.

	#to get a filepath : (snippet from chris's filepath_verify.rb file)
	## Get all the commit_files by the filepath column value
	 #   files = CommitFile.pluck(:filepath)
	 #   rgx = Regexp.new(regex)

	  #  files.each do |path| 
	  #    if path.match(rgx)
	  #      count+=1
	  #    end

	  #  end#end each

	#Test a Filepath that is vulnerable
	def verify_vulnerable
		issue = CodeReview.where(issue: 10854242).first
		filepath = _____ #replace with a reference to the filepath
		filepath.vulnerable? ? pass() : fail("Filepath declared not vulnerable when it is.")
	end  

	#Test a Filepath that isn't vulnerable 
	def verify_not_vulnerable
		filepath = ___ #replace with reference to the filepath
		filepath.vulnerable? ? fail("Filepath declared vulnerable when it isn't.") : pass()
	end

end 
