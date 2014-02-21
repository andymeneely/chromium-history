#Loads the CSV files of vulnerabilities and their associated review numbers
#Example:  CVE-2013-0838,10854242


require "csv"

class CveLoader

	@@CVES_PROPS = [:cve]
	def load_cve
		resultFile = "#{Rails.configuration.datadir}/cves/cves.csv"
		CSV.foreach(resultFile, :headers => true) do | row |
			cve = row[0]
			issues = row[1].scan(/\d+/)
			if issues.empty?
				next
			end
			cveModel = transfer(Cvenum.new, row[0], @@CVES_PROPS)
			cveModel.save  #should this check to see if the cve model is already there?
			link(cve, issues)

		end
	end

	def link(cve, issues)
		cveRecord = Cvenum.find_by_cve(cve)
		issues.each do |issue|
			codeReview = CodeReview.find_by_issue(issue)
			if codeReview.nil?
				puts "Issue #{issue} related to #{cve} not found in Code Review Table"
				next
			end
			codeReview.cvenums << cveRecord 
		end
	end

	# Given a model, a cve number, and a list of symbol properties, transfer the same attributes
	def transfer(model, cve, properties)
	    properties.each do |p|
	        model[p] = cve
	    end
	    model.save
	    model
	end
end

