# Loads the CSV files of vulnerabilities and their associated review numbers

require "csv"

class CveLoader
  RESULTS_FILE = "#{Rails.configuration.datadir}/cves/cves.csv"

  def load_cve
    parse_cves
    copy_to_db
  end

  def parse_cves
    uniqueCve = Set.new
    tmp = Rails.configuration.tmpdir
    table = CSV.open "#{tmp}/cvenums.csv", 'w+'
    link = CSV.open "#{tmp}/code_reviews_cvenums.csv", 'w+'
    CSV.foreach(RESULTS_FILE, :headers => true) do | row |
      cve = row[0].to_s.strip
      bounty = row[1].to_s.gsub(/[,$]/,'').to_f #strip comma & dollar, defaults to zero if empty
      issues = row[2].scan(/\d+/) #Mutliple code review ids split by non-numeric chars
      cvss_base = row[4].to_f        # CVSS Base Score
      cvss_av   = row[6].to_s.strip  # CVSS Access Vector
      cvss_ac   = row[7].to_s.strip  # CVSS Access Complexity
      cvss_au   = row[8].to_s.strip  # CVSS Authentication
      cvss_c    = row[9].to_s.strip  # CVSS Confidentiality
      cvss_i    = row[10].to_s.strip # CVSS Integrity
      cvss_a    = row[11].to_s.strip # CVSS Availability
      $stderr.puts "ERROR: CVE entry occurred twice: #{cve}" unless uniqueCve.add? cve
      $stderr.puts "ERROR: CVE #{cve} has no issues" if issues.empty?
      table << [cve, bounty, cvss_base, cvss_av, cvss_ac, cvss_au, cvss_c, cvss_i, cvss_a]
      issues.each do |issue| 
        link << [cve, issue]
      end
    end
    table.fsync
    link.fsync
  end

  def copy_to_db
    tmp = Rails.configuration.tmpdir
    PsqlUtil.copy_from_file 'cvenums', "#{tmp}/cvenums.csv"
    PsqlUtil.copy_from_file 'code_reviews_cvenums', "#{tmp}/code_reviews_cvenums.csv"
    ActiveRecord::Base.connection.execute <<-EOSQL
      WITH issues AS ((SELECT code_review_id from code_reviews_cvenums) 
                    EXCEPT (SELECT issue FROM code_reviews)) 
          DELETE FROM code_reviews_cvenums 
      WHERE code_review_id IN (SELECT code_review_id FROM issues);
    EOSQL
  end
end
