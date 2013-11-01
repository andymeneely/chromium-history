#Loads the CSV files of vulnerabilities and their associated review numbers
#Example:  CVE-2013-0838,10854242

class CveLoader

	@@CVES_PROPS = [:cve]
	def load_cve
		fileName = "chromium-history\\test\\data\\inspecting_vulnerabilities.csv"
		File.open(fileName).each do |line|
			line.chomp!
			cve = line.slice(0, line.index(","))
			reviewNum = line.slice(line.index(",") + 1, line.length)
			puts cve
			puts reviewNum
			if (review number doesnt exist)
				puts "Review Number " + reviewNum + " is not in our database."
			else
				#find review in the database
				if (the review already has a CVE)
					newCVE = get the CVE
					puts "Review Number " + reviewNum + " already has a CVE, " + newCVE
				else
					#add the cve number to the column "cve"
					cveModel = transfer(Cve.new, cve, @@CVES_PROPS)
					?????? << cveModel
					cveModel.save
				end
			end
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

### QUESTIONS ###

#1 How can I query the data base from here? I want to be able to...
# => check the code review table for a review number
#    SELECT EXISTS (SELECT reviewNum FROM code_reviews WHERE column = "code_review_id"); should return true/false
# => get the reviews corresponding cve
#    ??? SELECT cve FROM code_reviews WHERE column = "" ???

#2 This loader needs to load the CVE table and the code review table

