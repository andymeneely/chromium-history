chromium-history
================

Scripts and data related Chromium's history

Results: 
chromium_cves_clean.csv: auto generated CVEs mapped to reitveld ids
chromium_cves_dbcheck.csv: CVEs that require manual rechecking for reitveld ids
chromium_scrape_res.csv: uncleaned results of scrapeing 
groups.json : json formated hashtable of informal review groupings from the clean list
reveiws.json : json responses of all reviews on the clean list
NOTE: The main list of final CVEs to rietveld ids is in google docs under the CVEs sheet. This is not the same as the clean list. Both reviews and groups should be regenerated from this list. 

Scripts: 
ChromeCVEScraper.rb : scrapes for rietveld ids based on info from the NVD CVE
RietveldScraper.rb: class of utilities related to scrapeing code reviews for info, requires revision. 

dbcheck_rids.txt: list of rietveld ids that ran into erros when scraping. Many of these are restricted access even though thier google code issue id is open.  