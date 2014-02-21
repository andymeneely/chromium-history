#!/usr/bin/env ruby

require "nokogiri"
require "open-uri"
require "csv"
require "set"
require "uri"
require "openssl"
require "net/http"

#
# Written by Brian Spates
# script will find every CVE related to Chromium within a 
# national vulnerability database (nvd) xml file
# handed to the script when invoked ( < nvdxmlfile.xml) 
# It will then scrape webpages for rietveld ids with the information gathered
# from the nvd xml file.
#
class ChromeCveScraper 

	# The below line turns off Open Uri's ssl verification
	OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

	# Years included in this study
	CHROMIUM_NIST_YEARS = [
		2008,
		2009,
		2010,
		2011,
		2012,
		2013
	]

	# Csv headers for result files
	RESULT_HEADERS = [
		'CVE',
		'Rietveld Ids',
		'Google Code Issue Ids'
	]

	# Uri data
	NIST_URL = 'http://static.nvd.nist.gov/feeds/xml/cve/'
	NIST_FILE_R_PATH = '../../assets/'
	NIST_PREFIX = 'nvdcve-2.0-'
	NIST_SUFFIX = '.xml'
	RESULT_FILE_PATH = "/cves/chromium_scrape_res.csv"
	MANUAL_FILE_PATH = "/cves/chromium_manual_check.csv"
	REMOVED_FILE_PATH = "/cves/chromium_removed_from_study.csv"

	def initialize() 
		# Setup file paths
		@resultsFilePath = "#{Rails.configuration.datadir}#{RESULT_FILE_PATH}"
		@manualFilePath = "#{Rails.configuration.datadir}#{MANUAL_FILE_PATH}"
		@removedFilePath = "#{Rails.configuration.datadir}#{REMOVED_FILE_PATH}"
		@nistFile = File.expand_path(NIST_FILE_R_PATH, File.dirname(__FILE__)) + '/'
	end 

	def downloadNistData(year, filePath)
		puts "Downloading: #{NIST_URL}#{NIST_PREFIX}#{year}#{NIST_SUFFIX} \n"
		open("#{NIST_URL}#{NIST_PREFIX}#{year}#{NIST_SUFFIX}") do | f |
			File.open(filePath, "wb") do | file |
				puts ' - '
				file.puts f.read 
			end
		end
	end

	def setupCsvFile(path, headers)
		cves = Set.new
		if not File.exists?(path)
			CSV.open(path, 'ab')  do |header|
				header << headers
			end
		else
			cves = loadPrevCSVSet(path)
		end
		return cves
	end

	# Scrape for CVEs and thier Rietveld Fix Ids for all years
	def runAll()
		prevCves = Set.new

		prevCves = setupCsvFile(@resultsFilePath, RESULT_HEADERS)
		prevCves += setupCsvFile(@manualFilePath, RESULT_HEADERS)	
		prevCves +=	setupCsvFile(@removedFilePath, ['CVE', 'Reason'])

		cveManualFile = CSV.open(@manualFilePath, 'ab')

		# open csv file for results to be written to 
		cveResultsFile = CSV.open(@resultsFilePath, 'ab')

		cveRemovedFile = CSV.open(@removedFilePath, 'ab')


		CHROMIUM_NIST_YEARS.each  do | year |
			nistFilePath = "#{@nistFile}#{NIST_PREFIX}#{year}#{NIST_SUFFIX}"
			if not File.exists?(nistFilePath)
				downloadNistData(year, nistFilePath)
			end
			
			file = open(nistFilePath)
			doc = Nokogiri::XML(file)

			# search by products affected by vulnerability
			puts "Searching #{nistFilePath} for Chrome CVEs \n"
			entry1 = doc.xpath("//cpe-lang:fact-ref[starts-with(@name, 'cpe:/a:google:chrome:')]/../../..")

			cveLinks = findNistLinks(entry1, cveManualFile, prevCves)

			scrapeResults = scrapeCveLinks(cveLinks, cveRemovedFile)

			saveResults(cveResultsFile, scrapeResults)

			# search by references to chromium in vuln links
			entry2 = doc.xpath("//vuln:reference[contains(@href, 'chromium')]/../..")

			# Make sure the two sets don't overlap
			entry = entry2 - entry1

			cveLinks2 = findNistLinks(entry, cveManualFile, prevCves)

			scrapeResults2 = scrapeCveLinks(cveLinks2, cveRemovedFile)

			saveResults(cveResultsFile, scrapeResults2)
		end
	end

	# Search Nist xml doc for google code issue and chromium bug tracker links
	def findNistLinks(entry, cveManualFile, prevCves)
		results = Hash.new
		cve = ''
		entry.each do |nodes|
			id = nodes.xpath("vuln:cve-id")
			id.each do |n|
				cve = n.content
			end
			if(checkForRedundancies(cve, prevCves))
				puts "#{cve} already scraped, skipping..."
				next
			end
			results[cve] = Array.new
			links = nodes.xpath("vuln:references/vuln:reference")
			links.each do |n|
				temp = n.attribute("href")
				antemp = temp.to_s.scan(/http:\/\/code.google.com\/p\/chromium\/issues\/detail\?id=\d+|https:\/\/code.google.com\/p\/chromium\/issues\/detail\?id=\d+/)
				if(antemp[0] == nil)
					antemp = temp.to_s.scan(/http:\/\/bugs.chromium.org\/\d+/)
				end
				if(antemp[0] != nil)
					results[cve] << antemp
				end
			end
			if results[cve].empty?
				cveManualFile << [cve, '', '']
				puts "#{cve} had no links to google issues or the chromium bug tracker added to manual inspection list"
			end
		end
		return results
	end

	# Grab webpage with nokogiri 
	def getPage(link)

		# sleep needed to avoid being banned from website
		sleep(4)
	
		begin
			tempDoc = Nokogiri::HTML(open(link))
		rescue RuntimeError => e
			puts e
			redirect = e.to_s.scan(/redirection forbidden:/)
			if(redirect[0] == nil)
				return false;
			else
				newLink = e.to_s.scan(/-> (\S+)/)
				return getPage(newLink[0].to_s.gsub(/\[/, "").gsub(/\]/, "").gsub(/"/,""))
			end
		rescue SocketError => e
			puts e
			puts "connection error .. will attempt again"
			return getPage(link)
		rescue OpenURI::HTTPError => e
			puts e
			access_forbidden = e.to_s.scan(/403/)
			not_found = e.to_s.scan(/404/)
			if(access_forbidden[0] != nil)
				puts "#{link} not open to the public" 
				return false
			elsif(not_found[0] != nil)
				puts "#{link} not found"
				return false
			end
			puts "connection problem ... will attempt again"
			return getPage(link)
		end

		return tempDoc
	end

	def scrapeLink(link, gIds, rIds) 
		page = getPage(link)
		if page == false
			return
		end	
		parseGId(link, gIds)
		vId = checkForCodeR(page)
		if(vId[0] == nil)
			puts "none from google code page"
			scrapeDeep(page, gIds, rIds)
		end
		parseCodeRId(vId, rIds)
	end

	# Method invoked when a reitveld id is not present on a google code issue
	# It searches the issue page for repository links, that might have reitveld ids
	# It navigates to said repo page and scrapes for reitveld ids.
	def scrapeDeep(tempDoc, gIds, rIds)
		tId = tempDoc.xpath("//a[contains(@href, 'src.chromium.org/viewvc/chrome?view=rev')]")
		tId.each do | last |
			link = last.attribute("href")
			begin
				lastDoc = Nokogiri::HTML(open(link))
				vId = checkForCodeR(lastDoc)
				parseCodeRId(vId, rIds)
			rescue OpenURI::HTTPError => e
				puts e
				access_forbidden = e.to_s.scan(/404/)
				not_found = e.to_s.scan(/404/)
				if(access_forbidden[0] != nil || not_found != nil)
					next
				end
				scrapeLink(link, gIds, rIds)
				puts "connection problem ... will attempt again"
			end
		end
	end

	# Iterate over all the links found for a list of CVEs and scrape them
	def scrapeCveLinks(cves, removedFile)
		results = Hash.new
		cves.each do | cve, links |

			puts "Scraping for CVE: #{cve}"
			gIds = Array.new
			rIds = Set.new

			links.each do | link |
				if link.empty?
					next
				end
				link = link[0]
				scrapeLink(link, gIds, rIds)
			end
			if not rIds.empty?
				results[cve] = Hash.new
				results[cve]['g_ids'] = gIds
				results[cve]['r_ids'] = rIds
			elsif not gIds.empty?
				if webkitBug?(links)
					removedFile << [cve, 'webkit']
					puts "#{cve} removed from study because its a webkit bug, with no related chromium reviews."
				else
					results[cve] = Hash.new
					results[cve]['g_ids'] = gIds
					results[cve]['r_ids'] = rIds
				end
			end
		end

		return results
	end

	# Save scraping result ids to csv file
	def saveResults(csvResults, results) 
		results.keys.sort.each do |key|
			csvResults << [key, "#{results[key]['r_ids'].to_a.join(" ")}", "#{results[key]['g_ids'].join(" ")}"]
		end
	end

	# Scrapes for links to the code review pages
	def checkForCodeR(tempDoc)
		return tempDoc.xpath("//a[contains(@href, 'codereview.chromium') or contains(@href, 'chromiumcodereview.appspot')]")
	end

	# Check if google code issue is about a webkit bug
	# should only be run after all other options have been attempted
	def webkitBug?(links)
		links.each do |link|
			if link.empty?
				next
			end
			link = link[0]
			page = getPage(link)
			if page == false
				next
			end
			webkitLinks = page.xpath("//a[contains(@href, 'bugs.webkit') or contains(@href, 'trac.webkit')]")
			if not webkitLinks.empty?
				return true
			end
		end 
		return false
	end

	# parses google code issue ids from a url
	def parseGId(link, gIds)
		link.scan(/=(\d+)$/) do | id |
			gIds << id
		end
	end

	# parses rietveld ids from from a url and adds them to the set rId
	def parseCodeRId(vId, rIds)
		vId.each do | found |
			uri = URI.parse(found.content)
			rIds << uri.path.to_s.gsub(/\//, '').gsub(/show/, '').gsub(/(?<=\d)diff.*/, '')
		end
	end

	# See if we've already scraped for this CVE
	def checkForRedundancies(cve, cves)
		if(cves == nil)
			return false
		end
		cves.member?(cve)
	end

	# Load CVEs from a csv file
	def loadPrevCSVSet(path)
		cves = Set.new
		CSV.foreach(path, :headers => true) do |row|
			cves.add(row[0])
		end
		return cves
	end
end


# Drive it, needs to be run under rails enviroment
# in Terminal `rails r <path to this script>`
scraper = ChromeCveScraper.new
scraper.runAll()
