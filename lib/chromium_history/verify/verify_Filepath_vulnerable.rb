require_relative "verify_base"

class FilepathVulnerableVerify < verify_base

	#If a Filepath has ever been involved in a code review that inspected
	# a vulnerability, then this should return true.

	#Test a Filepath that is vulnerable
	def verify_vulnerable
		filepath = _____ #replace with a reference to the filepath
		filepath.vulnerable? ? pass() : fail("Filepath declared not vulnerable when it is.")
	end  

	#Test a Filepath that isn't vulnerable 
	def verify_not_vulnerable
		filepath = ___ #replace with reference to the filepath
		filepath.vulnerable? ? fail("Filepath declared vulnerable when it isn't.") : pass()
	end
	
end 
