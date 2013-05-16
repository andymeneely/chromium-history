require "./RietveldScraper"

# The below line turns off Open Uri's ssl verification
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

scraper = RietveldScraper.new
cves = scraper.loadAllCVEsCSVs("../results/chromium_cves_clean.csv")
reviews = scraper.queryReviews(cves)
scraper.printToJsonFile(reviews, "../results/reviews.json", "w+")