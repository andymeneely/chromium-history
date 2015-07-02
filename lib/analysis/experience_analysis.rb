# This script requiers the following R packages: "ROCR" , "bestglm" and "lsr"
require 'rinruby'
require 'utils/rinruby_util'

class ExperienceAnalysis
  include RinrubyUtil

  def initialize
    R.echo false, false
    R.eval <<-EOR
      options("width"=80) # For more readable output (when output is on)
    EOR
  end

  def run
    puts "\n===================================="
    puts "=== Developer Experience Results ==="
    puts "====================================\n"
    set_up_libraries
    connect_to_db do
      load_release_filepaths
      full_analysis
    end
  end

  # Set up libraries, including our own custom script
  def set_up_libraries
    R.eval <<-EOR
              suppressMessages(library(ROCR, warn.conflicts = FALSE, quietly=TRUE))
              suppressMessages(library(bestglm, warn.conflicts = FALSE, quietly=TRUE))
              suppressMessages(library(lsr, warn.conflicts = FALSE, quietly=TRUE))
              source('#{File.dirname(__FILE__)}/experience_functions.R')
    EOR
  end

  def load_release_filepaths
    R.eval <<-EOR
      release_filepaths <- dbGetQuery(con,
      "SELECT
        release,
        sloc,
        churn,

        perc_fast_reviews,
        perc_three_more_reviewers,

        avg_sheriff_hours,

        num_owners,
        avg_time_to_ownership,
        avg_commits_to_ownership,
        avg_ownership_distance,

        num_participants,

        num_security_experienced_participants / num_participants AS perc_security_experienced_participants,
        num_bug_security_experienced_participants / num_participants AS perc_bug_security_experienced_participants,
        num_build_experienced_participants / num_participants AS perc_build_experienced_participants,
        num_test_fail_experienced_participants / num_participants AS perc_test_fail_experienced_participants,
        num_compatibility_experienced_participants / num_participants AS perc_compatibility_experienced_participants,

        CASE WHEN num_security_experienced_participants > 0 THEN 1 ELSE 0 END AS any_security_experienced_participants,
        CASE WHEN num_bug_security_experienced_participants > 0 THEN 1 ELSE 0 END AS any_bug_security_experienced_participants,
        CASE WHEN num_build_experienced_participants > 0 THEN 1 ELSE 0 END AS any_build_experienced_participants,
        CASE WHEN num_test_fail_experienced_participants > 0 THEN 1 ELSE 0 END AS any_test_fail_experienced_participants,
        CASE WHEN num_compatibility_experienced_participants > 0 THEN 1 ELSE 0 END AS any_compatibility_experienced_participants,

        becomes_vulnerable
      FROM release_filepaths
      WHERE SLOC > 0
        AND num_participants > 0")
    EOR
  end

  def association(title, column, criteria)
    begin
    R.eval <<-EOR
      vulnerable <- release_filepaths$#{column}[release_filepaths$#{criteria}=="TRUE"]
      neutral <- release_filepaths$#{column}[release_filepaths$#{criteria}=="FALSE"]

      # MWW tests
      wt <- wilcox.test(vulnerable, neutral)

      # Risk factor analysis with mean discriminators
      median_vps <- median(vulnerable, na.rm=TRUE)
      median_nps <- median(neutral, na.rm=TRUE)
      thresh <- (median_vps + median_nps) / 2
      a <- vulnerable
      b <- neutral
      p_over_thresh <- length(a[a >thresh])/length(b[b >thresh])
      p_under_thresh <- length(a[a<=thresh])/length(b[b<=thresh])
      risk_factor <- p_over_thresh / p_under_thresh
      if ( is.finite(risk_factor) && risk_factor < 1.0 )
        risk_factor <- 1/risk_factor
      end

    EOR
    puts "--- #{title} ---"
    puts "  Mean of vulnerable:    #{R.pull("mean(vulnerable, na.rm=TRUE)")}"
    puts "  Mean of neutral:       #{R.pull("mean(neutral, na.rm=TRUE)")}"
    puts "    difference:          #{R.pull("mean(vulnerable, na.rm=TRUE) - mean(neutral, na.rm=TRUE)")}"
    puts "  Median of vulnerable:  #{R.pull("median(vulnerable, na.rm=TRUE)")}"
    puts "  Median of neutral:     #{R.pull("median(neutral, na.rm=TRUE)")}"
    puts "    difference:          #{R.pull("median(vulnerable, na.rm=TRUE) - median(neutral, na.rm=TRUE)")}"
    puts "  MWW p-value:           #{R.pull("wt$p.value")}"
    puts "  Per SLOC risk factors"
    puts "    threshold: #{R.pull('thresh')}"
    puts "    p(over), p(under) : #{R.pull('p_over_thresh')},#{R.pull('p_under_thresh')}"
    puts "    risk factor: #{R.pull('risk_factor')}"
    R.eval "rm(vulnerable, neutral, wt, a, b)"
    puts "\n"
    rescue
      puts "ERROR running association test for #{title}, #{column}"
    end
  end

  def run_associations
    association 'SLOC', 'sloc','becomes_vulnerable'

    association 'sloc', 'sloc', 'becomes_vulnerable'
    association 'churn', 'churn', 'becomes_vulnerable'

    association 'perc_fast_reviews', 'perc_fast_reviews', 'becomes_vulnerable'
    association 'perc_three_more_reviewers', 'perc_three_more_reviewers', 'becomes_vulnerable'

    association 'avg_sheriff_hours', 'avg_sheriff_hours', 'becomes_vulnerable'

    association 'num_owners', 'num_owners', 'becomes_vulnerable'
    association 'avg_time_to_ownership', 'avg_time_to_ownership', 'becomes_vulnerable'
    association 'avg_commits_to_ownership', 'avg_commits_to_ownership', 'becomes_vulnerable'
    association 'avg_ownership_distance', 'avg_ownership_distance', 'becomes_vulnerable'

    association 'num_participants', 'num_participants', 'becomes_vulnerable'
    association 'perc_security_experienced_participants', 'perc_security_experienced_participants', 'becomes_vulnerable'
    association 'perc_bug_security_experienced_participants', 'perc_bug_security_experienced_participants', 'becomes_vulnerable'
    association 'perc_build_experienced_participants', 'perc_build_experienced_participants', 'becomes_vulnerable'
    association 'perc_test_fail_experienced_participants', 'perc_test_fail_experienced_participants', 'becomes_vulnerable'
    association 'perc_compatibility_experienced_participants', 'perc_compatibility_experienced_participants', 'becomes_vulnerable'

    association 'any_security_experienced_participants', 'any_security_experienced_participants', 'becomes_vulnerable '
    association 'any_bug_security_experienced_participants', 'any_bug_security_experienced_participants', 'becomes_vulnerable '
    association 'any_build_experienced_participants', 'any_build_experienced_participants', 'becomes_vulnerable '
    association 'any_test_fail_experienced_participants', 'any_test_fail_experienced_participants', 'becomes_vulnerable '
    association 'any_compatibility_experienced_participants', 'any_compatibility_experienced_participants', 'becomes_vulnerable '
  end

  def full_analysis
    # R.echo true, false # pretty verbose. Useful for debugging rinruby
    R.echo false, false
    R.eval <<-EOR

      cat("-----Summary------")
      lapply(release_filepaths, function(x) cbind(summary(x)))
      cat("------------------")

      cat("-----------------------\n")
      cat("-------Spearman--------\n")
      cat("-----------------------\n")
      spearman_results <- cor(release_filepaths[,sapply(release_filepaths, is.numeric)], method="spearman", use="pairwise.complete.obs")
      print(spearman_results)

      cat("------------------\n")
      cat("-------MWW--------\n")
      cat("------------------\n")
    EOR
    R.echo false, false
    run_associations
    # R.prompt # use only for debugging
  end
end