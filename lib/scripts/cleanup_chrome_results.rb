require "set"
require "csv"
cves = Set.new
clean = CSV.open("../results/chromium_cves_clean.csv", 'ab')
dbcheck = CSV.open("../results/chromium_cves_dbcheck.csv", 'ab')
CSV.foreach("../results/chromium_scrape_res.csv", :headers => true) do | row |
	if(!cves.member?(row[0]))
		cves.add(row[0])
		if(row[1] != nil && row[1] != "")
			clean << [row[0], row[1].gsub(/show/, ''), row[2]]
		else
			dbcheck << row
		end
	end
	
end