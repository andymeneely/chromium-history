# This script requiers the following R packages: "ROCR" , "bestglm" and "lsr"
require 'rinruby'
class HypothesisTests

  def initialize
    R.echo false, false
  end

  def run
    puts "\n=== Hypothesis Test Results ===\n\n"
    connect_to_db
    Release.order(:date).each do |release|
      puts "="*80
      puts "===== FOR RELEASE #{release.name} ====="
      puts "="*80
      query_db(release.name)
      
      #puts "-"*80
      #puts "----- BUG ASSOCIATION FOR RELEASE #{release.name} -----"
      #puts "-"*80
      #bug_association_tests
      
      puts "-"*80
      puts "----- VULNERABILITY ASSOCIATION FOR RELEASE #{release.name} -----"
      puts "-"*80
      vulnerability_association_tests
    end

    puts "-"*80
    puts "----- LOGISTIC REGRESSION MODELING -----"
    puts "-"*80
    query_db_all
    r_modeling
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
    EOR
  end
  
  def query_db(release)
    R.eval <<-EOR
      data <- dbGetQuery(con, "SELECT * FROM release_filepaths WHERE release='#{release}'")
    EOR
  end

  def query_db_all
    R.eval <<-EOR
      
    EOR
  end

  def close_db
    R.eval <<-EOR
      dbDisconnect(con)
      dbUnloadDriver(drv)
    EOR
  end

  def bug_association_tests
    association 'SLOC', 'sloc','becomes_buggy'
    association 'Number of Reviews', 'num_reviews','becomes_buggy'
    association 'Number of Reviewers', 'num_reviewers','becomes_buggy'
    association 'Number of Participants', 'num_participants','becomes_buggy'
    association 'Avg # Non-Participating Reviewers','avg_non_participating_revs','becomes_buggy'
    association '% Reviews with 3 or more Reviewers','perc_three_more_reviewers','becomes_buggy'
    association '% Reviews with a Security-Experienced Participant', 'perc_security_experienced_participants','becomes_buggy'
    association 'Avg Security-Experienced Participants', 'avg_security_experienced_participants','becomes_buggy'
    association 'Average Prior Reviews with Owner', 'avg_reviews_with_owner','becomes_buggy'
    association 'Average Owner Familiarity Gap', 'avg_owner_familiarity_gap','becomes_buggy'
    association '% Reviews over 200 LOC/hour','perc_fast_reviews','becomes_buggy'
    association '% Reviews with a Potentially-Overlooked Patchset', 'perc_overlooked_patchsets','becomes_buggy'
    association 'Average Sheriff Hours','avg_sheriff_hours','becomes_buggy'
    
    association 'Pre Bugs / Future Bugs','num_pre_bugs','becomes_buggy'
    association 'Pre Feature Bugs / Future Bugs','num_pre_features','becomes_buggy'
    association 'Pre Compatibility Bugs / Future Bugs','num_pre_compatibility_bugs','becomes_buggy'
    association 'Pre Regression Bugs / Future Bugs','num_pre_regression_bugs','becomes_buggy'
    association 'Pre Security Bugs / Future Bugs','num_pre_security_bugs','becomes_buggy'
    association 'Pre Test Fails Bugs / Future Bugs','num_pre_tests_fails_bugs','becomes_buggy'
    association 'Pre Stability Crash Bugs / Future Bugs','num_pre_stability_crash_bugs','becomes_buggy'
    association 'Pre Build Bugs / Future Bugs','num_pre_build_bugs','becomes_buggy'
  end
  
  def vulnerability_association_tests
    association 'SLOC', 'sloc','vulnerable'
    association 'Number of Reviews', 'num_reviews','vulnerable'
    association 'Number of Reviewers', 'num_reviewers','vulnerable'
    association 'Number of Participants', 'num_participants','vulnerable'
    association '% Reviews with 3 or more Reviewers','perc_three_more_reviewers','vulnerable'
    association '% Reviews with a Security-Experienced Participant', 'perc_security_experienced_participants','vulnerable'
    association 'Avg Security-Experienced Participants', 'avg_security_experienced_participants','vulnerable'
    association 'Average Prior Reviews with Owner', 'avg_reviews_with_owner','vulnerable'
    association 'Average Owner Familiarity Gap', 'avg_owner_familiarity_gap','vulnerable'
    association '% Reviews over 200 LOC/hour','perc_fast_reviews','vulnerable'
    association '% Reviews with a Potentially-Overlooked Patchset', 'perc_overlooked_patchsets','vulnerable'
    association 'Average Sheriff Hours','avg_sheriff_hours','vulnerable'
    
    association 'Pre Bugs / Future Vulnerability','num_pre_bugs','becomes_vulnerable'
    association 'Pre Feature Bugs / Future Vulnerability','num_pre_features','becomes_vulnerable'
    association 'Pre Compatibility Bugs / Future Vulnerability','num_pre_compatibility_bugs','becomes_vulnerable'
    association 'Pre Regression Bugs / Future Vulnerability','num_pre_regression_bugs','becomes_vulnerable'
    association 'Pre Security Bugs / Future Vulnerability','num_pre_security_bugs','becomes_vulnerable'
    association 'Pre Test Fails Bugs / Future Vulnerability','num_pre_tests_fails_bugs','becomes_vulnerable'
    association 'Pre Stability Crash Bugs / Future Vulnerability','num_pre_stability_crash_bugs','becomes_vulnerable'
    association 'Pre Build Bugs / Future Vulnerability','num_pre_build_bugs','becomes_vulnerable'
    association 'Previous Vulnerability / Post Bugs','num_post_bugs','was_vulnerable'
  end

  def association(title, column, criteria)
    begin
    R.eval <<-EOR
      vulnerable <- data$#{column}[data$#{criteria}=="TRUE"]
      neutral <- data$#{column}[data$#{criteria}=="FALSE"]

      # Per SLOC populations
      vulnerable_per_sloc <- vulnerable/data$sloc[data$#{criteria}=="TRUE"]
      vulnerable_per_sloc <- vulnerable_per_sloc[is.finite(vulnerable_per_sloc)] #remove /0
      neutral_per_sloc <- neutral/data$sloc[data$#{criteria}=="FALSE"]
      neutral_per_sloc <- neutral_per_sloc[is.finite(neutral_per_sloc)] #remove /0
      
      # MWW tests
      op <- options(warn = (-1)) # suppress warnings
      wt <- wilcox.test(vulnerable, neutral)
      wt_per_sloc <- wilcox.test(vulnerable_per_sloc, neutral_per_sloc)
      options(op)

      # Risk factor analysis with mean discriminators
      median_vps <- median(vulnerable_per_sloc, na.rm=TRUE)
      median_nps <- median(neutral_per_sloc, na.rm=TRUE)
      thresh <- (median_vps + median_nps) / 2
      a <- vulnerable_per_sloc
      b <- neutral_per_sloc
      p_over_thresh <- length(a[a >thresh])/length(b[b >thresh]) 
      p_under_thresh <- length(a[a<=thresh])/length(b[b<=thresh]) 
      risk_factor <- p_over_thresh / p_under_thresh 
      if ( is.finite(risk_factor) && risk_factor < 1.0 )
        risk_factor <- 1/risk_factor
      end

    EOR
    puts "--- #{title} ---"
    puts "  Mean of #{criteria}:   #{R.pull("mean(vulnerable, na.rm=TRUE)")}"
    puts "  Mean of neutral:       #{R.pull("mean(neutral, na.rm=TRUE)")}"
    puts "  Median of #{criteria}: #{R.pull("median(vulnerable, na.rm=TRUE)")}"
    puts "  Median of neutral:     #{R.pull("median(neutral, na.rm=TRUE)")}"
    puts "  MWW p-value:           #{R.pull("wt$p.value")}"
    puts "  Per SLOC #{criteria} mean:   #{R.pull("mean(vulnerable_per_sloc, na.rm=TRUE)")}"
    puts "  Per SLOC neutral mean:       #{R.pull("mean(neutral_per_sloc, na.rm=TRUE)")}"
    puts "  Per SLOC #{criteria} median: #{R.pull("median(vulnerable_per_sloc, na.rm=TRUE)")}"
    puts "  Per SLOC neutral median:     #{R.pull("median(neutral_per_sloc, na.rm=TRUE)")}"
    puts "  Per SLOC MWW p-value:        #{R.pull("wt_per_sloc$p.value")}"
    puts "  Per SLOC risk factors"
    puts "    threshold: #{R.pull('thresh')}"
    puts "    p(over), p(under) : #{R.pull('p_over_thresh')},#{R.pull('p_under_thresh')}"
    puts "    risk factor: #{R.pull('risk_factor')}"
    R.eval "rm(vulnerable, vulnerable_per_sloc, neutral,neutral_per_sloc, wt,wt_per_sloc,a,b)"
    puts "\n"
    rescue 
      puts "ERROR running association test for #{title}, #{column}"
    end
  end

  def r_modeling
    begin 

    # Set up libraries
    R.eval <<-EOR
              suppressMessages(library(ROCR, warn.conflicts = FALSE, quietly=TRUE))
              suppressMessages(library(bestglm, warn.conflicts = FALSE, quietly=TRUE))
              suppressMessages(library(lsr, warn.conflicts = FALSE, quietly=TRUE))
    EOR
    R.eval <<-EOR
              source('~/chromium/history/lib/analysis/functions.R')
    EOR
    
    R.echo true, false
    #execute the functions on each release
    R.eval <<-EOR
        
        #Increase console width
        options("width"=250)

        release_filepaths_data <- dbGetQuery(con, "
        SELECT 
          release,
          sloc,
          num_vulnerabilities,
          num_pre_bugs,
          num_pre_features,
          num_pre_compatibility_bugs,
          num_pre_regression_bugs,
          num_pre_security_bugs,
          num_pre_tests_fails_bugs,
          num_pre_stability_crash_bugs,
          num_pre_build_bugs,
          num_post_bugs,
          num_pre_vulnerabilities,
          num_post_vulnerabilities,
          was_buggy,
          becomes_buggy,
          was_vulnerable,
          becomes_vulnerable
        FROM release_filepaths")
        

        # Split the data by relase
        r05 <- release_filepaths_data[ which(release_filepaths_data$release == "5.0"), -c(1)]
        r11 <- release_filepaths_data[ which(release_filepaths_data$release == '11.0'),-c(1)]
        r19 <- release_filepaths_data[ which(release_filepaths_data$release == '19.0'),-c(1)]
        r27 <- release_filepaths_data[ which(release_filepaths_data$release == '27.0'),-c(1)]
        r35 <- release_filepaths_data[ which(release_filepaths_data$release == '35.0'),-c(1)]

        cat("MODELING FOR RELEASE 05\n")
        release_modeling(r05,r11)

        cat("MODELING FOR RELEASE 11\n")
        release_modeling(r11,r19)

        cat("MODELING FOR RELEASE 19\n")
        release_modeling(r19,r27)

        cat("MODELING FOR RELEASE 27\n")
        release_modeling(r27,r35)

        cat("MODELING FOR RELEASE 35\n")
        release_modeling(r35,r35) #TODO check if its correct to predict with same data.
        

        rm(release_filepaths_data,r05,r11,r19,r27,r35)
    EOR
    R.echo false, false
    puts "\n"
    rescue 
      puts "ERROR running glm model test for Release #{title}"
    end
  end
end
