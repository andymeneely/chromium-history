# Kayla Nussbaum

require 'rinruby'
require 'utils/rinruby_util'

class CRAnalysisResults
	include RinrubyUtil

	def initialize
		R.echo false, false
		R.eval <<-EOR
			options("width"=250)
		EOR
	end
	
	def run
		puts "---------------------------------------------------------------"
		puts "-------------CODE REVIEW ANAYSIS: vulnerabilities--------------"
		puts "---------------------------------------------------------------"
		set_up_libraries
		connet_to_db do
			load_codeReviews
			full_analysis

		end
		R.eval 'save.image()'
	end

	def set_up_libraries
		R.eval <<-EOR
			suppressMessages(library(RPostgreSQL, warn.conflicts = FALSE, quietly = TRUE))
		EOR
	end

	def load_codeReviews
		R.eval <<-EOR
			code_revs <- dbGetQuery( con,
			"SELECT
			vuln_missed, vuln_misses
			non_participating_revs,
			total_reviews_with_owner,
			owner_familiarity_gap,
			total_sheriff_hours,
			churn")
		EOR
	end

	def full_analysis
		# non_participating_revs, total_reviews_with_owner, owner_familiarity_gap, total_sheriff_hours, churn
		R.eval <<-EOR
			spearman_nonPR_tRevs <- cor(code_revs$non_participating_revs, code_revs$total_reviews_with_owner, method="spearman")
			spearman_nonPR_oFamGap <- cor(code_revs$non_participating_revs, code_revs$owner_familiarity_gap, method="spearman")
			spearman_nonPR_sher <- cor(code_revs$non_participating_revs, code_revs$total_sheriff_hours, method="spearman")
			spearman_nonPR_churn <- cor(code_revs$non_participating_revs, code_revs$churn, method="spearman")

			spearman_tRevs_oFamGap <-cor(code_revs$total_reviews_with_owner, code_revs$owner_familiarity_gap, method="spearman")
			spearman_tRevs_sher <- cor(code_revs$total_reviews_with_owner, code_revs$total_sheriff_hours, method="spearman")
			spearman_tRevs_churn <- cor(code_revs$total_reviews_with_owner, code_revs$churn, method="spearman")
			
			spearman_oFamGap_sher <-cor(code_revs$owner_familiarity_gap, code_revs$total_sheriff_hours, method="spearman")
			spearman_oFamGap_churn <- cor(code_revs$owner_familiarity_gap, code_revs$churn, method="spearman")
			
			spearman_sher_churn <- cor(code_revs$total_sheriff_hours, code_revs$churn, method="spearman")

			spearman_vMissed_nonPR <- cor(code_revs$vuln_missed, code_revs$non_participating_revs, method="spearman")
			spearman_vMissed_tRevs <- cor(code_revs$vuln_missed, code_revs$total_reviews_with_owner, method="spearman")
			spearman_vMissed_oFamGap <- cor(code_revs$vuln_missed, code_revs$owner_familiarity_gap, method="spearman")
			spearman_vMissed_sher <- cor(code_revs$vuln_missed, code_revs$total_sheriff_hours, method="spearman")
			spearman_vMissed_churn <- cor(code_revs$vuln_missed, code_revs$churn, method="spearman")

			spearman_vMisses_nonPR <- cor(code_revs$vuln_misses, code_revs$non_participating_revs, method="spearman")
			spearman_vMisses_tRevs <- cor(code_revs$vuln_misses, code_revs$total_reviews_with_owner, method="spearman")
			spearman_vMisses_oFamGap <- cor(code_revs$vuln_misses, code_revs$owner_familiarilty_gap, method="spearman")
			spearman_vMisses_sher <- cor(code_revs$vuln_misses, code_revs$total_sheriff_hours, method="spearman")
			spearman_vMisses_churn <- cor(code_revs$vuln_misses, code_revs$churn, method="spearman")
		EOR
	end
		
