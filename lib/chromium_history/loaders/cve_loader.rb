#Loads the CSV files of vulnerabilities and their associated review numbers
#Example:  CVE-2013-0838,10854242

#class CVELoader

	@@CVES_PROPS = [:cve]
	def load_cve(fileName) 
		File.open(fileName).each do |line|
			line.chomp!
			cve = line.slice(0, line.index(","))
			reviewNum = line.slice(line.index(","), line.length)
			puts cve
			puts reviewNum
		#	if (review number doesnt exist)
		#		puts "Review Number " + reviewNum + " is not in our database."
		#	else
				#find review in the database
		#		if (the review already has a CVE)
		#			newCVE = get the CVE
		#			puts "Review Number " + reviewNum + " already has a CVE, " + newCVE
		#		else
					#add the cve number to the column "cve"
					cveModel = transfer(CVES.new, cve, reviewNum, @@CVES_PROPS)
		#		end
		#	end
		end
	end

	# Given a model, a ???, and a list of symbol properties, transfer the same attributes
	def transfer(model, cve, properties)
	    properties.each do |p|
	        model[p] = cve
	    end
	    model.save
	    model
	end
#end

load_cve("C:\\Users\\Shannon\\Documents\\GitHub\\chromium-history\\test\\data\\inspecting_vulnerabilities.csv")
