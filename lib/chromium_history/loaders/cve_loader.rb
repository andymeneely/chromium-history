#Loads the CSV files of vulnerabilities and their associated review numbers
#Example:  CVE-2013-0838,10854242


class CveLoader

	@@CVES_PROPS = [:cve]
	def load_cve
		fileName = "#{Rails.configuration.datadir}/inspecting_vulnerabilities.csv"
		File.open(fileName).each do |line|
			line.chomp!
			cve = line.slice(0, line.index(","))
			reviewNum = line.slice(line.index(",") + 1, line.length)
			
			cveModel = transfer(Cve.new, cve, @@CVES_PROPS)
			cveModel.save  #should this check to see if the cve model is already there?

			#find review in the database
			codeReview = CodeReview.find_by_issue(reviewNum)
			if (codeReview == nil)
				puts "Review Number " + reviewNum + " is not in our database."
			else
				#if there is already a cve there
				if (codeReview.cve?)
					oldCVE = codeReview.cve
					if (oldCVE != cve)
						puts "Review Number " + reviewNum + " already has a CVE, " + oldCVE
					end #checking for bad CVE match up
				else
					#add the cve number to the column "cve"
					codeReview.cve = cve 
					codeReview.save
				end #if cve
			end #if codereview
		end #csv file line loop
	end #load cve method

	# Given a model, a cve number, and a list of symbol properties, transfer the same attributes
	def transfer(model, cve, properties)
	    properties.each do |p|
	        model[p] = cve
	    end
	    model.save
	    model
	end
end

