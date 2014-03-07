#Loads the CSV files of vulnerabilities and their associated review numbers
#Example:  CVE-2013-0838,10854242


require "csv"
require "google_drive"

class CveLoader

	@@CVES_PROPS = [:cve]
	def load_cve

		resultFile = get_google_spreadsheet()

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
				$stderr.puts "Issue #{issue} related to #{cve} not found in Code Review Table"
				next
			end
			codeReview.cvenums << cveRecord 
		end
	end

	# Download result set from Google Docs
	def get_google_spreadsheet
		downloadFile = "#{Rails.configuration.datadir}/cves/cves.csv"
		if File.exists?(downloadFile)
			File.delete(downloadFile)
		end
		session = get_gdocs_session()
		spreadsheet = session.spreadsheet_by_key("0AitmN6wcrwF3dG14cDk1S2ZIZFJxMzBwRHIxd3N5TUE")
		spreadsheet.export_as_file(downloadFile, 'csv', 22)
		downloadFile
	end

	# Sign into Google Docs using username and password specified in credentials.yml
	def get_gdocs_session
		google_creds_yml = YAML.load_file("#{Rails.root}/config/credentials.yml")['google-docs']
		GoogleDrive.login(google_creds_yml['user-name'], google_creds_yml['password'])
	end

	# Munge data from different results sets to produce a holistic result set
	def build_result_set
		session = get_gdocs_session()
		manualFile = "#{Rails.configuration.datadir}/cves/manuals.csv"
		oldScrapeFile = "#{Rails.configuration.datadir}/cves/gen1_scrape.csv"
		newScrapeFile = "#{Rails.configuration.datadir}/cves/gen2_scrape.csv"
		spreadsheet = session.spreadsheet_by_key("0AitmN6wcrwF3dG14cDk1S2ZIZFJxMzBwRHIxd3N5TUE")
		spreadsheet.export_as_file(manualFile, 'csv', 25)
		spreadsheet.export_as_file(oldScrapeFile, 'csv', 15)
		spreadsheet.export_as_file(newScrapeFile, 'csv', 18)
		list = Hash.new

		list = addCveIssues(list, manualFile, 0, 2)
		list = addCveIssues(list, oldScrapeFile, 0, 1)
		list = addCveIssues(list, newScrapeFile, 0, 1)

		CSV.open("#{Rails.configuration.datadir}/cves/cves.csv", 'wb')  do |header|
			header << ['CVE','Issue']
		end
		cveFile = CSV.open("#{Rails.configuration.datadir}/cves/cves.csv", 'ab')
		list.each do |cve, issues|
			cveFile << [cve, issues.to_a.join(' ')]
		end
		File.delete(manualFile)
		File.delete(oldScrapeFile)
		File.delete(newScrapeFile)
	end

	# Add to unique CVE -> Rietvel Issues list
	def addCveIssues(cveList, csvFile, cveCol, issueCol) 
		CSV.foreach(csvFile, :headers => true) do | row |
			cve = row[cveCol]
			if row[issueCol].nil?
				next
			end
			issues = row[issueCol].scan(/\d+/)
			if issues.empty?
				next
			end
			if not cveList.has_key? cve
				cveList[cve] = Set.new
			end
			issues.collect{ |issue| cveList[cve].add(issue)}
		end
		cveList
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
