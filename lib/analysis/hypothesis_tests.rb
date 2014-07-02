require 'rinruby'

class HypothesisTests

  def initialize
    R.echo false, false
  end

  def run
    puts "\n=== Hypothesis Test Results ===\n\n"
    connect_to_db
    association_tests
    close_db
  end

  def connect_to_db
    conf = Rails.configuration.database_configuration[Rails.env]
    R.eval <<-EOR
      library(DBI)
      library(RPostgreSQL)
      drv <- dbDriver("PostgreSQL")
      con <- dbConnect(drv, 
                       user="#{conf['username']}", 
                       password="#{conf['password']}", 
                       dbname="#{conf['database']}")
      data <- dbReadTable(con, "release_filepaths")
    EOR
  end
  
  def close_db
    R.eval <<-EOR
      dbDisconnect(con)
      dbUnloadDriver(drv)
    EOR
  end

  def association_tests
    association 'SLOC', 'sloc'
    association 'Number of Reviews', 'num_reviews'
    association 'Number of Reviewers', 'num_reviewers'
    association 'Number of Participants', 'num_participants'
    association 'Avg # Non-Participating Reviewers','avg_non_participating_revs'
    association '% Reviews with 3 or more Reviewers','perc_three_more_reviewers'
    association '% Reviews with a Security-Experienced Participant', 'perc_security_experienced_participants'
    association 'Avg Security-Experienced Participants', 'avg_security_experienced_participants'
    association 'Average Prior Reviews with Owner', 'avg_reviews_with_owner'
    association 'Average Owner Familiarity Gap', 'avg_owner_familiarity_gap'
    association '% Reviews over 200 LOC/hour','perc_fast_reviews'
    association '% Reviews with a Potentially-Overlooked Patchset', 'perc_overlooked_patchsets'
  end

  def association(title, column)
    begin
    R.eval <<-EOR
      vulnerable <- data$#{column}[data$vulnerable=="TRUE"]
      neutral <- data$#{column}[data$vulnerable=="FALSE"]

      vulnerable_per_sloc <- vulnerable/data$sloc[data$vulnerable=="TRUE"]
      vulnerable_per_sloc <- vulnerable_per_sloc[is.finite(vulnerable_per_sloc)] #remove /0
      neutral_per_sloc <- neutral/data$sloc[data$vulnerable=="FALSE"]
      neutral_per_sloc <- neutral_per_sloc[is.finite(neutral_per_sloc)] #remove /0
      
      op <- options(warn = (-1)) # suppress warnings
      wt <- wilcox.test(vulnerable, neutral)
      wt_per_sloc <- wilcox.test(vulnerable_per_sloc, neutral_per_sloc)
      options(op)
    EOR
    puts "--- #{title} ---"
    puts "  Mean of vulnerable: #{R.pull("mean(vulnerable, na.rm=TRUE)")}"
    puts "  Mean of neutral: #{R.pull("mean(neutral, na.rm=TRUE)")}"
    puts "  MWW p-value: #{R.pull("wt$p.value")}"
    puts "  Per SLOC vulnerable mean: #{R.pull("mean(vulnerable_per_sloc, na.rm=TRUE)")}"
    puts "  Per SLOC neutral mean: #{R.pull("mean(neutral_per_sloc, na.rm=TRUE)")}"
    puts "  Per SLOC MWW p-value: #{R.pull("wt_per_sloc$p.value")}"
    R.eval "rm(vulnerable, vulnerable_per_sloc, neutral,neutral_per_sloc, wt)"
    puts "\n"
    rescue 
      puts "ERROR running association test for #{title}, #{column}"
    end
  end

end
