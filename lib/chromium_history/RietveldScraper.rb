require "nokogiri"
require "open-uri"
require "CSV"
require "uri"
require "openssl"
require "json"

# written by Brian Spates
# class contains functions to scrape info from the Chromium-
# Rietveld code review site
class RietveldScraper

	def initialize()
		@errorIds = File.open("dbcheck_rIds.txt", "ab")
	end
	def loadAllCVEsCSVs(pathToCSV)
		cves = Hash.new
		CSV.foreach(pathToCSV, :headers => true )do |row|
			temp = row[1].scan(/\d+/)
			cves[row[0]] = temp
		end
		return cves
	end

	# handles the actual page quering and error handling
	def queryJsonRietveld(link, id, json_resp)
		begin
			temp = Nokogiri::HTML(open(link))
			json_resp[id] = JSON.parse(temp) 
			#call a method to do something with the json response here
		rescue OpenURI::HTTPError => e
			puts "connection error: #{e} - #{id}"
			puts "hit enter to continue"
			wait = gets
		rescue JSON::ParserError => je
			@errorIds.puts "#{id} "
		end
	end
	
	# Method takes hash with rietveld ids as keys and an array of patch ids- 
	# as values and grabs the json representation of that patch set
	def queryPacthSets(patchIds)
		patches	= Hash.new
		hashOfArrays.each do |rId, patchIds|
			patchIds.each do | id |
				link = "https://codereview.chromium.org/api/#{key}/#{id}"
				queryJsonRietveld(link, id, patches)
			end
		end
		return patches
	end
	
	# Method takes a hash with CVEs as keys and an array of Rietveld ids - 
	# as values and grabs the json  representation of that review 
	def queryReviews(cves)
		reviews = Hash.new
		cves.each do |cve, rIds|
			rIds.each do | id |
				link = "https://codereview.chromium.org/api/#{id}"
				queryJsonRietveld(link, id, reviews)
			end
		end
		return reviews
	end
	
	# prints a json response 
	def printJsonRietveld(json_resp)
		json_resp.each do |k, v|
			puts 
			puts k
			puts v
		end
	end
	
	def printToJsonFile(json_resp, fileName, mode)
		doc = JSON.pretty_generate(json_resp)
		File.open(fileName, mode) do |file|
			file.write(doc)
		end
	end
	
	def loadJsonFile(fileName)
		doc = JSON.parse(IO.read(fileName))	
	end
	# establishes groups of reviewers and reviewees
	def parseJsonForGroups(reviews)
		developers = Hash.new
		reviews.each do | review |
			review.each do | r| 
				tempDevs = r["reviewers"]
				if(!tempDevs.nil?)
					tempDevs.each do | dev|
						if(!developers.has_key?(dev))
							developers[dev] = Array.new
						end
						developers[dev] << r["owner_email"]
					end
				end
			end
		end
		return developers
	end

end

