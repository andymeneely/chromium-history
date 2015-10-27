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
			"SELECT * FROM developer_snapshots")
		EOR
	end
	
	def full_analysis
		puts "-----------------------"
		puts "--------Spearman-------"
		puts "-----------------------"
		R.eval <<-EOR
			spearman_deg_sher <- cor(dev_snap$sheriff_hours, dev_snap$degree, method="spearman")
		EOR
		puts <<-EOS
			degree vs sheriff hours: #{R.pull("spearman_deg_sher")} (n=#{R.pull("length(dev_snap$degree")})
		EOS
	end

end
