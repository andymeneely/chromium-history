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
      
      #puts "-"*80
      #puts "----- VULNERABILITY ASSOCIATION FOR RELEASE #{release.name} -----"
      #puts "-"*80
      #vulnerability_association_tests

      puts "-"*80
      puts "----- MODELING FOR RELEASE #{release.name} -----"
      puts "-"*80
      prediction_model(release.name)
    end
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
    association 'Avg # Non-Participating Reviewers','avg_non_participating_revs','vulnerable'
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

  def prediction_model(title)
    begin     
    R.eval <<-EOR
        # Extract relevant prediction data
        release <- data[,c(3,20:26,33)] #TODO List these out so we don't have magic numbers
        
        # Remove files where there were no bugs of any kind, or if it had no SLOC
        # i.e. The subset must have at least on bug of ANY kind, and SLOC > 0
        # Confirm if we need to remove the points with all variables are zero but outcome is TRUE.

        release <- subset(release, (release$num_pre_features !=0 |
                                    release$num_pre_compatibility_bugs !=0 | 
                                    release$num_pre_regression_bugs !=0 | 
                                    release$num_pre_security_bugs !=0 | 
                                    release$num_pre_tests_fails_bugs != 0 | 
                                    release$num_pre_stability_crash_bugs != 0 |
                                    release$num_pre_build_bugs != 0 | 
                                    release$becomes_vulnerable != FALSE) 
                                  & release$sloc > 0)
        # Normalize and center data, added one to the values to be able to calculate log to zero. log(1)=0
        release = cbind(as.data.frame(log(release[,-c(9)] + 1)), becomes_vulnerable = release$becomes_vulnerable)
  
        options(warn=-1) # Suppress warnings as we are getting : glm.fit: fitted probabilities numerically 0 or 1 occurred
        
        # Individuali Variable  Models
        fit_null <- glm(formula = becomes_vulnerable ~ 1, 
                        data = release, family = "binomial")
        
        fit_control <- glm(formula = becomes_vulnerable ~ sloc, 
                           data = release, family = "binomial")

        fit_num_pre_features <- glm(formula= becomes_vulnerable ~ sloc + num_pre_features, 
                                    data = release, family = "binomial")
        
        fit_num_pre_compatibility_bugs <- glm (formula= becomes_vulnerable ~ sloc + num_pre_compatibility_bugs, 
                                               data = release, family = "binomial")

        fit_num_pre_regression_bugs <- glm (formula= becomes_vulnerable ~ sloc + num_pre_regression_bugs, 
                                            data = release, family = "binomial")

        fit_num_pre_security_bugs <- glm (formula= becomes_vulnerable ~ sloc + num_pre_security_bugs, 
                                          data = release, family = "binomial")

        fit_num_pre_tests_fails_bugs <- glm (formula= becomes_vulnerable ~ sloc + num_pre_tests_fails_bugs, 
                                             data = release, family = "binomial")

        fit_num_pre_stability_crash_bugs <- glm (formula= becomes_vulnerable ~ sloc + num_pre_stability_crash_bugs, 
                                                 data = release, family = "binomial")

        fit_num_pre_build_bugs <- glm (formula= becomes_vulnerable ~ sloc + num_pre_build_bugs, 
                                         data = release, family = "binomial")
         
        fit_all <- glm (formula= becomes_vulnerable ~ ., 
                        data = release, family = "binomial")

        # Category Based Models
        fit_features <- glm (formula= becomes_vulnerable ~ sloc + num_pre_features, 
                             data = release, family = "binomial")
        
        fit_security <- glm (formula= becomes_vulnerable ~ sloc + num_pre_security_bugs, 
                             data = release, family = "binomial")
        
        fit_stability <- glm (formula= becomes_vulnerable ~ sloc + num_pre_stability_crash_bugs +
                              num_pre_compatibility_bugs + num_pre_regression_bugs, 
                              data = release, family = "binomial")
        
        fit_build <- glm (formula= becomes_vulnerable ~ sloc + num_pre_build_bugs + num_pre_tests_fails_bugs, 
                          data = release, family = "binomial")        

        options(warn=0)
    EOR
    puts "--- GLM model for release #{title} ---"
    R.echo true, false
    R.eval "summary(release)"
    R.eval <<-EOR
      # Summary Individual Models
      summary(fit_null)
      summary(fit_control)
      summary(fit_num_pre_features)
      summary(fit_num_pre_compatibility_bugs)
      summary(fit_num_pre_regression_bugs)
      summary(fit_num_pre_security_bugs)
      summary(fit_num_pre_tests_fails_bugs)
      summary(fit_num_pre_stability_crash_bugs)
      summary(fit_num_pre_build_bugs)

      # Summary Category Models
      summary(fit_security)
      summary(fit_features)
      summary(fit_stability)
      summary(fit_build)
    EOR
    R.echo false, false
    R.eval <<-EOR
    rm(release, fit_null, fit_control, fit_num_pre_features, 
       fit_num_pre_compatibility_bugs, fit_num_pre_regression_bugs, 
       fit_num_pre_security_bugs, fit_num_pre_tests_fails_bugs, 
       fit_num_pre_stability_crash_bugs, fit_num_pre_build_bugs, 
       fit_security, fit_features, fit_stability, fit_build)
    EOR
    puts "\n"
    rescue 
      puts "ERROR running glm model test for Release #{title}"
    end
  end
end
