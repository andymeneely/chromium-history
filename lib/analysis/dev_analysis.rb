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
		puts "\n====================="
		puts "=== Correlations? ==="
		puts "\n====================="
		
		connect_to_db do
			load_snapshots
			full_analysis
		end
	end

	def load_snapshots
		R.eval <<-EOR
			dev_snap <- dbGetQuery( con,
			"SELECT 
			dev_id, degree, 
			closeness, betweenness,
			sheriff_hrs,
			sec_exp, bugsec_exp,
			start_date, end_date 
			FROM developer_snapshots")
		EOR
	end
	
	def full_analysis
		puts "---------------------------------------------"
		puts "----Spearman on deg/closeness/betweenness----"
		puts "---------------------------------------------"
		R.eval <<-EOR
			spearman_deg_sher <- cor(dev_snap$sheriff_hrs, dev_snap$degree, method="spearman")
			spearman_close_sher <- cor(dev_snap$sheriff_hrs, dev_snap$closeness, method="spearman")
			spearman_bet_sher <- cor(dev_snap$sheriff_hrs, dev_snap$betweenness, method="spearman")
			spearman_close_bet <- cor(dev_snap$closeness, dev_snap$betweenness, method="spearman")
			spearman_close_deg <- cor(dev_snap$closeness, dev_snap$degree, method="spearman")
			spearman_bet_deg <- cor(dev_snap$betweenness, dev_snap$degree, method="spearman")
		EOR
		puts <<-EOS
			closeness vs betweenness: #{R.pull("spearman_close_bet")} 
			closeness vs degree: #{R.pull("spearman_close_deg")} 
			betweenness vs degree: #{R.pull("spearman_bet_deg")} 
		EOS
		puts "---------------------------------------------"
		puts "----Spearman on sheriff_hrs VS things--------"
		puts "---------------------------------------------"
		puts <<-EOS
			degree vs sheriff hours: #{R.pull("spearman_deg_sher")} 
			closeness vs sheriff hours: #{R.pull("spearman_close_sher")} 
			betweenness vs sheriff hours: #{R.pull("spearman_bet_sher")} 
		EOS
		
	end

end
