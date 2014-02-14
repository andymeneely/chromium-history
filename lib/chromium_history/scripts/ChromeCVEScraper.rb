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

# The below line turns off Open Uri's ssl verification
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

# Method invoked when a reitveld id is not present on a google code issue
# It searches the issue page for repository links, that might have reitveld ids
# It navigates to said repo page and scrapes for reitveld ids.
def lastChance(tempDoc, rId)
	tId = tempDoc.xpath("//a[contains(@href, 'src.chromium.org/viewvc/chrome?view=rev')]")
	tId.each do | last |
		link = last.attribute("href")
		begin
			lastDoc = Nokogiri::HTML(open(link))
			vId = checkForCodeR(lastDoc, rId)
			parseCodeRId(vId, rId)
		rescue OpenURI::HTTPError => e
			puts e
			access_forbidden = e.to_s.scan(/404/)
			not_found = e.to_s.scan(/404/)
			if(access_forbidden[0] != nil || not_found != nil)
				next
			end
			getPage(rId, gId, link)
			puts "connection problem ... will attempt again"
		end
	end
end

# Scrapes for links to the code review pages
def checkForCodeR(tempDoc, rId)
	vId = tempDoc.xpath("//a[contains(@href, 'codereview.chromium') or contains(@href, 'chromiumcodereview.appspot')]")
end

# parses google code issue ids from a url
def parseGId(link, gId)
	link.scan(/=(\d+)$/) do | jah |
		gId << jah
	end
	return gId
end

# parses rietveld ids from from a url and adds them to the set rId
def parseCodeRId(vId, rId)
	vId.each do | found |
		uri = URI.parse(found.content)
		rId << uri.path.to_s.gsub(/\//, '').gsub(/show/, '')
	end
end

# method naviagtes to a google code issue page 
# and scrapes for reitveld ids
def getPage(rId, gId, link)
	
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
			return getPage(rId, gId, newLink[0].to_s.gsub(/\[/, "").gsub(/\]/, "").gsub(/"/,""))
		end
	rescue SocketError => e
		puts e
		puts "connection error .. will attempt again"
		return getPage(rId, gId, link)
	rescue OpenURI::HTTPError => e
		puts e
		access_forbidden = e.to_s.scan(/403/)
		not_found = e.to_s.scan(/404/)
		if(access_forbidden[0] != nil || not_found[0] != nil)
			return false
		end
		puts "connection problem ... will attempt again"
		return getPage(rId, gId, link)
	end
	gId = parseGId(link, gId)
	vId = checkForCodeR(tempDoc, rId)
	if(vId[0] == nil)
		puts "none from google code page"
		lastChance(tempDoc, rId)
		return true
	end
	parseCodeRId(vId, rId)
	
	return true;
end

# method parses XML from given file for CVEs relating to Chromium
# and invokes the scraping process from parsed info.
def getInfo(entry, res, cves)
	temp = ""
	cve = ""
	entry.each do |nodes|
		rId = Set.new
		gId = Array.new
		open = -1
		id = nodes.xpath("vuln:cve-id")
		puts id
		id.each do |n|
			cve = n.content
		end
		if(checkForRedundancies(cves, cve))
			next
		end
		links = nodes.xpath("vuln:references/vuln:reference")
		links.each do |n|
			temp = n.attribute("href")
			antemp = temp.to_s.scan(/http:\/\/code.google.com\/p\/chromium\/issues\/detail\?id=\d+|https:\/\/code.google.com\/p\/chromium\/issues\/detail\?id=\d+/)
			if(antemp[0] == nil)
				antemp = temp.to_s.scan(/http:\/\/bugs.chromium.org\/\d+/)
			end
			antemp.each do | link |
				open = getPage(rId, gId, link)	
			end	
		end
		if(open==false)
			puts "access restricted"
		end
		res << [cve, "#{rId.to_a.join(" ")}", "#{gId.join(" ")}", open]
	end
end

def checkForRedundancies(cves, cve)
	if(cves == nil)
		return false
	end
	cves.member?(cve)
end

def setupResultsFile(path)
	CSV.open(path, 'ab')  do |header|
		header << ['CVE', 'Rietveld Ids', 'Google Code Issue Ids', 'Open to Public?'] 
	end
end

def loadPrevCSVSet(path)
	cves = Set.new
	CSV.foreach(path, :headers => true) do |row|
		cves.add(row[0])
	end
	return cves
end
# name of csv file you want to write results to
# script expects predefined headers
resultsFile = "data/CVEs/chromium_scrape_res.csv"

nistYears = [
	2008,
	2009,
	2010,
	2011,
	2012,
	2013
	]

nistDomain = 'http://static.nvd.nist.gov'
nistUrl = '/feeds/xml/cve/'
nistFile = 'lib/assets/nist_data/'
nistPrefix = 'nvdcve-2.0-'
nistSuffix = '.xml'

#open XML given by argument
nistYears.each  do | year |
	nistFilePath = "#{nistFile}#{nistPrefix}#{year}#{nistSuffix}"
	puts nistFilePath
	file = open(nistFilePath)
	doc = Nokogiri::XML(file)
	if not File.exists?(resultsFile)
		setupResultsFile(resultsFile)	
	else
		# loads the result set to avoid re-scrapping CVEs
		cves = loadPrevCSVSet(resultsFile)
	end
	# open csv file for results to be written to s
	res = CSV.open(resultsFile, 'ab')

	# search by products affected by vulnerability
	entry1 = doc.xpath("//cpe-lang:fact-ref[starts-with(@name, 'cpe:/a:google:chrome:')]/../../..")
	getInfo(entry1, res, cves)

	# search by references to chromium in vuln links
	entry2 = doc.xpath("//vuln:reference[contains(@href, 'chromium')]/../..")

	# Make sure the two sets don't overlap
	entry = entry2 - entry1
	getInfo(entry, res, cves) 
end

