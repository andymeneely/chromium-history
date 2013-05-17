require "./RietveldScraper"
scraper = RietveldScraper.new
reviews = scraper.loadJsonFile("../results/reviews.json")
devs = scraper.parseJsonForGroups(reviews)
scraper.printToJsonFile(devs, "../results/groups.json", "w+")
