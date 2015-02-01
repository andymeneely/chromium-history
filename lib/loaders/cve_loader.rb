# Downloads and loads the CSV files of vulnerabilities and their associated review numbers

require "csv"
require "google_drive"
require "google/api_client"

class CveLoader
  RESULTS_FILE = "#{Rails.configuration.datadir}/cves/cves.csv"

  def load_cve
    download_csv #unless Rails.env == 'development' 
    parse_cves
    copy_to_db
  end
  
  # Sign into Google Docs 
  # username and password specified in credentials.yml
  def login
    google_creds_yml = YAML.load_file("#{Rails.root}/config/credentials.yml")['google-docs']
    client = Google::APIClient.new
    auth = client.authorization
    auth.client_id = google_creds_yml['client-id']
    auth.client_secret = google_creds_yml['client-secret']
    auth.scope =
        "https://www.googleapis.com/auth/drive " +
        "https://spreadsheets.google.com/feeds/"
    auth.redirect_uri = 'urn:ietf:wg:oauth:2.0:oob'#google_creds_yml['redirect_uri']
    print("1. Open this page:\n%s\n\n" % auth.authorization_uri)
    print("2. Enter the authorization code shown in the page: ")
    auth.code = $stdin.gets.chomp
    auth.fetch_access_token!
    access_token = auth.access_token
    GoogleDrive.login_with_oauth(access_token)
  end

  #Go out to Google Drive and download the sheet
  def download_csv
    File.delete(RESULTS_FILE) if File.exists?(RESULTS_FILE)
    session = login()
    spreadsheet = session.spreadsheet_by_key(Rails.configuration.google_spreadsheets['key'])
    worksheet = spreadsheet.worksheet_by_title 'CVEs'
    worksheet.export_as_file(RESULTS_FILE, 'csv', Rails.configuration.google_spreadsheets['gid'])
  end

  def parse_cves
    uniqueCve = Set.new
    tmp = Rails.configuration.tmpdir
    table = CSV.open "#{tmp}/cvenums.csv", 'w+'
    link = CSV.open "#{tmp}/code_reviews_cvenums.csv", 'w+'
    CSV.foreach(RESULTS_FILE, :headers => true) do | row |
      cve = row[0]
      issues = row[1].scan(/\d+/) #Mutliple code review ids split by non-numeric chars
      $stderr.puts "ERROR: CVE entry occurred twice: #{cve}" unless uniqueCve.add? cve
      $stderr.puts "ERROR: CVE #{cve} has no issues" if issues.empty?
      table << [cve]
      issues.each do |issue| 
        link << [cve, issue]
      end
    end
    table.fsync
    link.fsync
  end

  def copy_to_db
    tmp = Rails.configuration.tmpdir
    ActiveRecord::Base.connection.execute("COPY cvenums FROM '#{tmp}/cvenums.csv' DELIMITER ',' CSV")
    ActiveRecord::Base.connection.execute("COPY code_reviews_cvenums FROM '#{tmp}/code_reviews_cvenums.csv' DELIMITER ',' CSV")
    ActiveRecord::Base.connection.execute <<-EOSQL
      WITH issues AS ((SELECT code_review_id from code_reviews_cvenums) 
                    EXCEPT (SELECT issue FROM code_reviews)) 
          DELETE FROM code_reviews_cvenums 
      WHERE code_review_id IN (SELECT code_review_id FROM issues);
    EOSQL
  end
end
