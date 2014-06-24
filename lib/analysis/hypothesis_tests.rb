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
    #TODO Re-enable these tests once they are loaded
    #association 'Code Churn', 'churn'
    association 'Number of Reviews', 'num_reviews'
    association 'Number of Reviewers', 'num_reviewers'
    association 'Number of Participants', 'num_participants'
    #association '% Reviews with a Non-Participating Reviewer','perc_non_part_reviewers'
    association '% Reviews with a Security-Experienced Participant', 'perc_security_experienced_participants'
    #association 'Average Prior Reviews with Owner', 'avg_reviews_with_owner'
    #association 'Average Owner Familiarity Gap', 'avg_owner_familiarity_gap'
    #association '% Reviews over 200 LOC/hour','perc_fast_reviews'
    #association '% Reviews with a Potentially-Overlooked Patchset', 'perc_overlooked_patchsets'
  end

  def association(title, column)
    begin
    R.eval <<-EOR
      vulnerable <- data$#{column}[data$vulnerable=="TRUE"]
      neutral <- data$#{column}[data$vulnerable=="FALSE"]
      op <- options(warn = (-1)) # suppress warnings
      wt <- wilcox.test(vulnerable, neutral)
      options(op)
    EOR
    puts "--- #{title} ---"
    puts "  Mean of vulnerable: #{R.pull("mean(vulnerable, na.rm=TRUE)")}"
    puts "  Mean of neutral: #{R.pull("mean(neutral, na.rm=TRUE)")}"
    puts "  MWW p-value: #{R.pull("wt$p.value")}"
    R.eval "rm(vulnerable, neutral, wt)"
    puts "\n"
    rescue 
      puts "ERROR running association test for #{title}, #{column}"
    end
  end

end
