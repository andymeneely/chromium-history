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

        becomes_vulnerable
      FROM release_filepaths
      WHERE SLOC > 0
        AND num_participants > 0")
    EOR
  end

  def full_analysis
    R.echo true, false
    R.eval <<-EOR

      cat("-----Summary------")
      lapply(release_filepaths, function(x) cbind(summary(x)))
      cat("------------------")

      cat("-----------------------\n")
      cat("-------Spearman--------\n")
      cat("-----------------------\n")
      spearman_results <- cor(release_filepaths[,sapply(release_filepaths, is.numeric)], method="spearman", use="pairwise.complete.obs")
      print(spearman_results)
      cat("------------------")
    EOR
    # R.prompt # use only for debugging
    R.echo false, false
  end
end
