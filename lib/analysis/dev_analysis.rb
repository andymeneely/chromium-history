# Samantha Oxley

require 'rinruby'
require 'utils/rinruby_util'

class DevAnalysis
	include RinrubyUtil

	def initialize
		R.echo false, false
		R.eval <<-EOR
			options("width"=250)
		EOR
	end

	def run
		puts "----------------------------------------------------------------"
		puts "------------SOCIAL NETWORK ANALYSIS: sheriff_hours--------------"
		puts "----------------------------------------------------------------"
	 	set_up_libraries	
		connect_to_db do
			load_snapshots
			full_analysis
			load_snapshots_no_zeros
			full_analysis_no_zeros
		end
    		R.eval 'save.image()'
	end

	def set_up_libraries
    		R.eval <<-EOR
      			suppressMessages(library(RPostgreSQL, warn.conflicts = FALSE, quietly=TRUE))
    		EOR
 	end

	def load_snapshots
		R.eval <<-EOR
			dev_snap <- dbGetQuery( con,
			"SELECT 
			dev_id, degree, 
			own_count,
			closeness, betweenness,
			sheriff_hrs, has_sheriff_hrs,
			vuln_misses_1yr, vuln_misses_6mo,
			vuln_fixes_owned, vuln_fixes,
			perc_vuln_misses, 
			sec_exp, bugsec_exp,
			start_date, end_date 
			FROM developer_snapshots")
		EOR
	end
	
	def load_snapshots_no_zeros
		R.eval <<-EOR
			dev_no_zeros <- dbGetQuery( con,
			"SELECT 
			dev_id, degree,
			own_count, 
			closeness, betweenness,
			sheriff_hrs, has_sheriff_hrs,
			sec_exp, bugsec_exp,
			start_date, end_date 
			FROM developer_snapshots
			WHERE has_sheriff_hrs = 1")
		EOR
	end
	
	def full_analysis
		# missed_vuln changed to vuln_misses_1yr, vuln_misses_6mo, vuln_fixes_owned, and vuln_fixes
		# using `perc_missed_vuln` for now instead of `perc_vuln_misses` until updated in dev snapshot table
			# variable is named `spearman_percVM` to ultimately reflect perc_vuln_misses once changed
		R.eval <<-EOR
			spearman_close_bet <- cor(dev_snap$closeness, dev_snap$betweenness, method="spearman")
			spearman_close_deg <- cor(dev_snap$closeness, dev_snap$degree, method="spearman")
			spearman_bet_deg <- cor(dev_snap$betweenness, dev_snap$degree, method="spearman")
		
			spearman_deg_sher <- cor(dev_snap$sheriff_hrs, dev_snap$degree, method="spearman")
			spearman_close_sher <- cor(dev_snap$sheriff_hrs, dev_snap$closeness, method="spearman")
			spearman_bet_sher <- cor(dev_snap$sheriff_hrs, dev_snap$betweenness, method="spearman")
			
			spearman_vuln_deg <- cor(dev_snap$vuln_misses_1yr, dev_snap$degree, method="spearman")
			spearman_vuln_sher <- cor(dev_snap$vuln_misses_1yr, dev_snap$sheriff_hrs, method="spearman")
			spearman_vuln_close <- cor(dev_snap$vuln_misses_1yr, dev_snap$closeness, method="spearman")
			spearman_vuln_bet <- cor(dev_snap$vuln_misses_1yr, dev_snap$betweenness, method="spearman")

			spearman_vuln6mo_deg <- cor(dev_snap$vuln_misses_6mo, dev_snap$degree, method="spearman")
			spearman_vuln6mo_sher <- cor(dev_snap$vuln_misses_6mo, dev_snap$sheriff_hrs, method="spearman")
			spearman_vuln6mo_close <- cor(dev_snap$vuln_misses_6mo, dev_snap$closeness, method="spearman")
			spearman_vuln6mo_bet <- cor(dev_snap$vuln_misses_6mo, dev_snap$betweenness, method="spearman")

			spearman_vulnFO_deg <- cor(dev_snap$vuln_fixes_owned, dev_snap$degree, method="spearman")
			spearman_vulnFO_sher <- cor(dev_snap$vuln_fixes_owned, dev_snap$sheriff_hrs, method="spearman")
			spearman_vulnFO_close <- cor(dev_snap$vuln_fixes_owned, dev_snap$closeness, method="spearman")
			spearman_vulnFO_bet <- cor(dev_snap$vuln_fixes_owned, dev_snap$betweenness, method="spearman")

			spearman_vulnF_deg <- cor(dev_snap$vuln_fixes, dev_snap$degree, method="spearman")
			spearman_vulnF_sher <- cor(dev_snap$vuln_fixes, dev_snap$sheriff_hrs, method="spearman")
			spearman_vulnF_close <- cor(dev_snap$vuln_fixes, dev_snap$closeness, method="spearman")
			spearman_vulnF_bet <- cor(dev_snap$vuln_fixes, dev_snap$betweenness, method="spearman")

			spearman_percVM_deg <- cor(dev_snap$perc_vuln_misses, dev_snap$degree, method="spearman")
			spearman_percVM_sher <- cor(dev_snap$perc_vuln_misses, dev_snap$sheriff_hrs, method="spearman")
			spearman_percVM_close <- cor(dev_snap$perc_vuln_misses, dev_snap$closeness, method="spearman")
			spearman_percVM_bet <- cor(dev_snap$perc_vuln_misses, dev_snap$betweenness, method="spearman")

			op <- options(warn = (-1)) 	
			wil_deg_sher <- wilcox.test(dev_snap$degree ~ dev_snap$has_sheriff_hrs, paired=FALSE)
			wil_close_sher <- wilcox.test(dev_snap$closeness ~ dev_snap$has_sheriff_hrs, paired=FALSE)
			wil_bet_sher <- wilcox.test(dev_snap$betweenness ~ dev_snap$has_sheriff_hrs, paired=FALSE)
			options(op)
		EOR
		# Print results
		puts "----------------------------------------------------------------------"
		puts "-------------Spearman on deg/closeness/betweenness--------------------"
		puts "----------------------------------------------------------------------"
		puts <<-EOS
			closeness vs betweenness: #{R.pull("spearman_close_bet")} 
			closeness vs degree: #{R.pull("spearman_close_deg")} 
			betweenness vs degree: #{R.pull("spearman_bet_deg")} 
		EOS
		puts "----------------------------------------------------------------------"
		puts "-------Spearman on sheriff_hrs VS deg/closeness/betweenness-----------"
		puts "----------------------------------------------------------------------"
		puts <<-EOS
			degree vs sheriff hours: #{R.pull("spearman_deg_sher")} 
			closeness vs sheriff hours: #{R.pull("spearman_close_sher")} 
			betweenness vs sheriff hours: #{R.pull("spearman_bet_sher")} 
		EOS
		puts "----------------------------------------------------------------------"
		puts "---Spearman on vulnerability misses 1yr VS shrf_hrs/deg/close/bet-----"
		puts "----------------------------------------------------------------------"
		puts <<-EOS
			vuln misses 1yr vs degree: #{R.pull("spearman_vuln_deg")}
			vuln misses 1yr vs sheriff hours: #{R.pull("spearman_vuln_sher")} 
			vuln misses 1yr vs closeness: #{R.pull("spearman_vuln_close")} 
			vuln misses 1yr vs betweenness: #{R.pull("spearman_vuln_bet")} 
		EOS
		puts "----------------------------------------------------------------------"
		puts "---Spearman on vulnerability misses 6mo VS shrf_hrs/deg/close/bet-----"
		puts "----------------------------------------------------------------------"
		puts <<-EOS
			vuln misses 6mo vs degree: #{R.pull("spearman_vuln6mo_deg")}
			vuln misses 6mo vs sheriff hours: #{R.pull("spearman_vuln6mo_sher")} 
			vuln misses 6mo vs closeness: #{R.pull("spearman_vuln6mo_close")} 
			vuln misses 6mo vs betweenness: #{R.pull("spearman_vuln6mo_bet")} 
		EOS
		puts "----------------------------------------------------------------------"
		puts "---Spearman on vulnerability fixes owned VS shrf_hrs/deg/close/bet----"
		puts "----------------------------------------------------------------------"
		puts <<-EOS
			vuln fixes owned vs degree: #{R.pull("spearman_vulnFO_deg")}
			vuln fixes owned vs sheriff hours: #{R.pull("spearman_vulnFO_sher")} 
			vuln fixes owned vs closeness: #{R.pull("spearman_vulnFO_close")} 
			vuln fixes owned vs betweenness: #{R.pull("spearman_vulnFO_bet")} 
		EOS
		puts "----------------------------------------------------------------------"
		puts "------Spearman on vulnerability fixes VS shrf_hrs/deg/close/bet-------"
		puts "----------------------------------------------------------------------"
		puts <<-EOS
			vuln fixes vs degree: #{R.pull("spearman_vulnF_deg")}
			vuln fixes vs sheriff hours: #{R.pull("spearman_vulnF_sher")} 
			vuln fixes vs closeness: #{R.pull("spearman_vulnF_close")} 
			vuln fixes vs betweenness: #{R.pull("spearman_vulnF_bet")} 
		EOS
		puts "----------------------------------------------------------------------"
		puts "-Spearman on percent vulnerabilities missed VS shrf_hrs/deg/close/bet-"
		puts "----------------------------------------------------------------------"
		puts <<-EOS
			perc vuln misses vs degree: #{R.pull("spearman_percVM_deg")}
			perc vuln misses vs sheriff hours: #{R.pull("spearman_percVM_sher")}
			perc vuln misses vs closeness: #{R.pull("spearman_percVM_close")}
			perc vuln misses vs betweenness: #{R.pull("spearman_percVM_bet")}
		EOS
		puts "----------------------------------------------------------------------"
		puts "----Wilcoxon p-values on sheriff_hrs VS deg/closeness/betweenness-----"
		puts "----------------------------------------------------------------------"
		puts <<-EOS
			degree vs sheriff hours p-value: #{R.pull("wil_deg_sher$p.value")}
        median with sheriff_hrs: #{R.pull("median(dev_snap$degree[dev_snap$has_sheriff_hrs==1])")}
        median w/o sheriff_hrs: #{R.pull("median(dev_snap$degree[dev_snap$has_sheriff_hrs==0])")}
			closeness vs sheriff hours p-value: #{R.pull("wil_close_sher$p.value")} 
        median with sheriff_hrs: #{R.pull("median(dev_snap$closeness[dev_snap$has_sheriff_hrs==1])")}
        median w/o sheriff_hrs: #{R.pull("median(dev_snap$closeness[dev_snap$has_sheriff_hrs==0])")}
			betweeness vs sheriff hours p-value: #{R.pull("wil_bet_sher$p.value")} 
        median with sheriff_hrs: #{R.pull("median(dev_snap$betweenness[dev_snap$has_sheriff_hrs==1])")}
        median w/o sheriff_hrs: #{R.pull("median(dev_snap$betweenness[dev_snap$has_sheriff_hrs==0])")}
    		
		EOS

	end
	def full_analysis_no_zeros
		# First evaluate in R
		R.eval <<-EOR
			spearman_deg_sher_no0 <- cor(dev_no_zeros$sheriff_hrs, dev_no_zeros$degree, method="spearman")
			spearman_close_sher_no0 <- cor(dev_no_zeros$sheriff_hrs, dev_no_zeros$closeness, method="spearman")
			spearman_bet_sher_no0 <- cor(dev_no_zeros$sheriff_hrs, dev_no_zeros$betweenness, method="spearman")
		EOR
		# Print results from R
		puts "\n"
		puts "****************************************************************"
		puts "\n"
		puts "----------------------------------------------------------------"
		puts "-----What if we ONLY look at non-zero sheriff hour values?------"
		puts "---------------------------Spearman-----------------------------"
		puts <<-EOS
			degree vs sheriff hours: #{R.pull("spearman_deg_sher_no0")} 
			closeness vs sheriff hours: #{R.pull("spearman_close_sher_no0")} 
			betweenness vs sheriff hours: #{R.pull("spearman_bet_sher_no0")} 
		EOS
	end

end
