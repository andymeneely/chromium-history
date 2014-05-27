#Loads the CSV files of vulnerabilities and their associated review numbers
#Example:  CVE-2013-0838,10854242


require "csv"
require "google_drive"

class CveLoader
	RESULTS_FILE = "/cves/cves.csv"
	def load_cve
		if Rails.env == 'development' 
			resultFile = "#{Rails.configuration.datadir}#{RESULTS_FILE}"
		else
			resultFile = build_result_set()
		end
		uniqueCve = Set.new
		table = CSV.open "#{Rails.configuration.datadir}/tmp/cvenums.csv", 'w+'
		link = CSV.open "#{Rails.configuration.datadir}/tmp/code_reviews_cvenums.csv", 'w+'
		CSV.foreach(resultFile, :headers => true) do | row |
			if uniqueCve.add? row[0]
				cve = row[0]
				issues = row[1].scan(/\d+/)
				if issues.empty?
					next
				end
				table << [cve]
				issues.each do |issue| 
					link << [cve, issue]
				end
			end
		end
		table.fsync
		link.fsync
		datadir = File.expand_path(Rails.configuration.datadir)
		ActiveRecord::Base.connection.execute("COPY cvenums FROM '#{datadir}/tmp/cvenums.csv' DELIMITER ',' CSV")
		ActiveRecord::Base.connection.execute("COPY code_reviews_cvenums FROM '#{datadir}/tmp/code_reviews_cvenums.csv' DELIMITER ',' CSV")
		ActiveRecord::Base.connection.execute("WITH issues AS ((SELECT code_review_id from code_reviews_cvenums) EXCEPT (SELECT issue FROM 
											   code_reviews)) DELETE FROM code_reviews_cvenums WHERE code_review_id IN (SELECT code_review_id 
											   FROM issues);")
	end

	# Download result set from Google Docs
	def get_google_spreadsheet
		downloadFile = "#{Rails.configuration.datadir}#{RESULTS_FILE}"
		if File.exists?(downloadFile)
			File.delete(downloadFile)
		end
		session = get_gdocs_session()
		spreadsheet = session.spreadsheet_by_key(Rails.configuration.google_spreadsheets['key'])
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
		spreadsheet = session.spreadsheet_by_key(Rails.configuration.google_spreadsheets['key'])
		spreadsheet.export_as_file(manualFile, 'csv', Rails.configuration.google_spreadsheets['manualinspection'])
		spreadsheet.export_as_file(oldScrapeFile, 'csv', Rails.configuration.google_spreadsheets['oldscrape'])
		spreadsheet.export_as_file(newScrapeFile, 'csv', Rails.configuration.google_spreadsheets['newscrape'])
		list = Hash.new

		list = addCveIssues(list, manualFile, 0, 2)
		list = addCveIssues(list, oldScrapeFile, 0, 1)
		list = addCveIssues(list, newScrapeFile, 0, 1)

		resultFile = "#{Rails.configuration.datadir}#{RESULTS_FILE}"
		CSV.open(resultFile, 'wb')  do |header|
			header << ['CVE','Issue']
		end
		cveFile = CSV.open(resultFile, 'ab')
		list.each do |cve, issues|
			cveFile << [cve, issues.to_a.join(' ')]
		end
		File.delete(manualFile)
		File.delete(oldScrapeFile)
		File.delete(newScrapeFile)
		resultFile
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
end
