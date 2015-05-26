require 'rinruby'

class FeedbackAnalysis

  def initialize
    R.echo false, false
  end

  def run
    connect_to_db
    r_modeling
    close_db
  end

  def connect_to_db
    conf = Rails.configuration.database_configuration[Rails.env]
    # To install these packages locally, run R on the command line
    # and then run
    # >>> install.packages("DBI")
    # >>> install.packages("PostgreSQL")
    # >>> install.packages("ROCR")
    # >>> install.packages("bestglm")
    # >>> install.packages("lsr")
    # >>> install.packages("stats")
    # >>> install.packages("BaylorEdPsych")
    R.echo false,false
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

  def close_db
    R.echo false, false
    R.eval <<-EOR
      dbDisconnect(con)
      dbUnloadDriver(drv)
    EOR
  end

  def r_modeling
    begin 
    R.echo false,false
    # Set up libraries
    R.eval <<-EOR
              suppressMessages(library(ROCR, warn.conflicts = FALSE, quietly=TRUE))
              suppressMessages(library(bestglm, warn.conflicts = FALSE, quietly=TRUE))
              suppressMessages(library(lsr, warn.conflicts = FALSE, quietly=TRUE))
	      suppressMessages(library(stats,warn.conflicts = FALSE, quietly=TRUE))
	      suppressMessages(library(BaylorEdPsych,warn.conflicts = FALSE,quietly=TRUE))
    EOR

    R.echo true, false
	
    #Add Modeling functions
    R.eval <<-EOR
      release_modeling <- function(release){
        options(warn=-1)
        
        # Do the analysis only for files with bugs and sloc
        release <- subset(release, (release$num_future_regression_bugs !=0 |
                              release$num_future_compat_bugs !=0 |
                              release$num_future_security_bugs !=0 |
                              release$num_future_stabil_crash_bugs !=0 |
                              release$num_future_stabil_mem_address_bugs != 0)
                            & release$sloc > 0)

        # Normalize and center data, added 2 to the values to allow for positive responses, necessary for Gamma...tbd
	release = cbind(as.data.frame(log(release[,c(1:11)] + 2)))
			
	# Modeling (forward selection)
	# Individual Models
	fit_null_reg <- glm(formula = num_future_regression_bugs ~ 1, data = release, family = Gamma)
	fit_null_comp <- glm(formula = num_future_compat_bugs ~ 1, data = release, family = Gamma)
	fit_null_sec <- glm(formula = num_future_security_bugs ~ 1, data = release, family = Gamma)
	fit_null_stab_crash <- glm(formula = num_future_stabil_crash_bugs ~ 1, data = release, family = Gamma)
	fit_null_stab_mem <- glm(formula = num_future_stabil_mem_address_bugs ~ 1, data = release, family = Gamma)

	fit_control_reg <- glm(formula = num_future_regression_bugs ~ sloc, data = release, family = Gamma)
	fit_control_comp <- glm(formula = num_future_compat_bugs ~ sloc, data = release, family = Gamma)
	fit_control_sec <- glm(formula = num_future_security_bugs ~ sloc, data = release, family = Gamma)
	fit_control_stab_crash <- glm(formula = num_future_stabil_crash_bugs ~ sloc, data = release, family = Gamma)
	fit_control_stab_mem <- glm(formula = num_future_stabil_mem_address_bugs ~ sloc, data = release, family = Gamma)
	  
	fit_reg_words <- glm(formula = num_future_regression_bugs ~ sloc + num_regression_word_used, data = release, family = Gamma)
	reg_words_glmfit1 <- as.numeric(1-(exp(logLik(fit_null_reg))/exp(logLik(fit_reg_words)))^(2/nrow(release)))
	reg_words_glmfit2 <- PseudoR2(fit_reg_words)

	fit_comp_words <- glm(formula = num_future_compat_bugs ~ sloc + num_compat_word_used, data = release, family = Gamma)
	comp_words_glmfit1 <- as.numeric(1-(exp(logLik(fit_null_comp))/exp(logLik(fit_comp_words)))^(2/nrow(release)))
	comp_words_glmfit2 <- PseudoR2(fit_comp_words)

	fit_sec_words <- glm(formula = num_future_security_bugs ~ sloc + num_security_word_used, data = release, family = Gamma)
	sec_words_glmfit1 <- as.numeric(1-(exp(logLik(fit_null_sec))/exp(logLik(fit_sec_words)))^(2/nrow(release)))
	sec_words_glmfit2 <- PseudoR2(fit_sec_words)

	fit_stab_crash_words <- glm(formula = num_future_stabil_crash_bugs ~ sloc + num_stabil_crash_word_used, data = release, family = Gamma)
	stab_crash_words_glmfit1 <- as.numeric(1-(exp(logLik(fit_null_stab_crash))/exp(logLik(fit_stab_crash_words)))^(2/nrow(release)))
	stab_crash_words_glmfit2 <- PseudoR2(fit_stab_crash_words)

	fit_stab_mem_words <- glm(formula = num_future_stabil_mem_address_bugs ~ sloc + num_stabil_mem_address_word_used, data = release, family = Gamma)
	stab_mem_words_glmfit1 <- as.numeric(1-(exp(logLik(fit_null_stab_mem))/exp(logLik(fit_stab_mem_words)))^(2/nrow(release)))
	stab_mem_words_glmfit2 <- PseudoR2(fit_stab_mem_words)

	fit_reg_words_no_sloc <- glm(formula = num_future_regression_bugs ~ num_regression_word_used, data = release, family = Gamma)
	fit_comp_words_no_sloc <- glm(formula = num_future_compat_bugs ~ num_compat_word_used, data = release, family = Gamma)
	fit_sec_words_no_sloc <- glm(formula = num_future_security_bugs ~ num_security_word_used, data = release, family = Gamma)
	fit_stab_crash_words_no_sloc <- glm(formula = num_future_stabil_crash_bugs ~ num_stabil_crash_word_used, data = release, family = Gamma)
	fit_stab_mem_words_no_sloc <- glm(formula = num_future_stabil_mem_address_bugs ~ num_stabil_mem_address_word_used, data = release, family = Gamma)

	# Display Results:
	cat("\nRelease Summary\n")
	print(summary(release))

	cat("\nSpearman's Correlation for regression words and bugs\n")
	print(cor(release[,c(2,7)],method="spearman"))

	cat("\nSpearman's Correlation for compatibility words and bugs\n")
	print(cor(release[,c(3,8)],method="spearman"))
	  
	cat("\nSpearman's Correlation for security words and bugs\n")
	print(cor(release[,c(4,9)],method="spearman"))

	cat("\nSpearman's Correlation for stability_crash words and bugs\n")
	print(cor(release[,c(5,10)],method="spearman"))
	  
	cat("\nSpearman's Correlation for stability_mem words and bugs\n")
	print(cor(release[,c(6,11)],method="spearman"))
	  
	cat("\n# Summary for regression models\n")
	cat("fit_null_reg\n")
	print(summary(fit_null_reg))
	cat("fit_control_reg\n")
	print(summary(fit_control_reg))
	cat("fit_reg_words\n")
	print(summary(fit_reg_words))
	cat("fit_reg_words_no_sloc\n")
	print(summary(fit_reg_words_no_sloc))
	cat("Generalized Determination Coefficient\n")
	print(reg_words_glmfit1)
	print("")
	print(reg_words_glmfit2)
	  
	cat("\n# Summary for compatibility models\n")
	cat("fit_null_comp\n")
	print(summary(fit_null_comp))
	cat("fit_control_comp\n")
	print(summary(fit_control_comp))
	cat("fit_comp_words\n")
	print(summary(fit_comp_words))
	cat("fit_comp_words_no_sloc\n")
	print(summary(fit_comp_words_no_sloc))
	cat("Generalized Determination Coefficient\n")
	print(comp_words_glmfit1)
	print("")
	print(comp_words_glmfit2)

	cat("\n# Summary for security models\n")
	cat("fit_null_sec\n")
	print(summary(fit_null_sec))
	cat("fit_control_sec\n")
	print(summary(fit_control_sec))
	cat("fit_sec_words\n")
	print(summary(fit_sec_words))
	cat("fit_sec_words_no_sloc\n")
	print(summary(fit_sec_words_no_sloc))
	cat("Generalized Determination Coefficient\n")
	print(sec_words_glmfit1)
	print("")
	print(sec_words_glmfit2)
	  
	cat("\n# Summary for stability_crash models\n")
	cat("fit_null_stab_crash\n")
	print(summary(fit_null_stab_crash))
	cat("fit_control_stab_crash\n")
	print(summary(fit_control_stab_crash))
	cat("fit_stab_crash_words\n")
	print(summary(fit_stab_crash_words))
	cat("fit_stab_crash_words_no_sloc\n")
	print(summary(fit_stab_crash_words_no_sloc))
	cat("Generalized Determination Coefficient\n")
	print(stab_crash_words_glmfit1)
	print("")
	print(stab_crash_words_glmfit2)
	  
	cat("\n# Summary for stability_mem models\n")
	cat("fit_null_stab_mem\n")
	print(summary(fit_null_stab_mem))
	cat("fit_control_stab_mem\n")
	print(summary(fit_control_stab_mem))
	cat("fit_stab_mem_words\n")
	print(summary(fit_stab_mem_words))
	cat("fit_stab_mem_words_no_sloc\n")
	print(summary(fit_stab_mem_words_no_sloc))
	cat("Generalized Determination Coefficient\n")
	print(stab_mem_words_glmfit1)
	print("")
	print(stab_mem_words_glmfit2)

	options(warn=0)
      }
    EOR

    R.echo true, false
    #execute the modeling function on each release
    R.eval <<-EOR
      #Increase console width
      options("width"=250)
      
      #Get data for total tw use in reviews vs tot bugs
      #overall_rev_twuse <- dbReadTable(con,"rev_overall_tw_bugs")

      #Separate data per label type
      #reg <- overall_rev_twuse[ which(overall_rev_twuse$label == "type-bug-regression"),-c(1,2)]
      #comp <- overall_rev_twuse[ which(overall_rev_twuse$label == "type-compat"),-c(1,2)]
      #sec <- overall_rev_twuse[ which(overall_rev_twuse$label == "type-bug-security"),-c(1,2)]
      #stab_c <- overall_rev_twuse[ which(overall_rev_twuse$label == "stability-crash"),-c(1,2)]
      #stab_m <- overall_rev_twuse[ which(overall_rev_twuse$label == "stability-memory-addresssanitizer"),-c(1,2)]

      #Get data for total tw use in reviews not fixing any data vs tot bugs
      #nonfix_rev_twuse <- dbReadTable(con,"rev_nonfix_tw_bugs")

      #Separate data per label type
      #reg_n <- overall_rev_twuse[ which(nonfix_rev_twuse$label == "type-bug-regression"),-c(1,2)]
      #comp_n <- overall_rev_twuse[ which(nonfix_rev_twuse$label == "type-compat"),-c(1,2)]
      #sec_n <- overall_rev_twuse[ which(nonfix_rev_twuse$label == "type-bug-security"),-c(1,2)]
      #stab_cn <- overall_rev_twuse[ which(nonfix_rev_twuse$label == "stability-crash"),-c(1,2)]
      #stab_mn <- overall_rev_twuse[ which(nonfix_rev_twuse$label == "stability-memory-addresssanitizer"),-c(1,2)]
      
      #cat("\nOverall Spearman's Correlation for Regression\n")
      #print(cor(reg[,c(2,1)],method="spearman"))

      #cat("\nOverall Spearman's Correlation for Compatibility\n")
      #print(cor(comp[,c(2,1)],method="spearman"))
      
      #cat("\nOverall Spearman's Correlation for Security\n")
      #print(cor(sec[,c(2,1)],method="spearman"))
      
      #cat("\nOverall Spearman's Correlation for Stability Crash\n")
      #print(cor(stab_c[,c(2,1)],method="spearman"))

      #cat("\nOverall Spearman's Correlation for Stability Mem Addr\n")
      #print(cor(stab_m[,c(2,1)],method="spearman"))

      #cat("\nNonFix Spearman's Correlation for Regression\n")
      #print(cor(reg_n[,c(2,1)],method="spearman"))

      #cat("\nNonFix Spearman's Correlation for Compatibility\n")
      #print(cor(comp_n[,c(2,1)],method="spearman"))

      #cat("\nNonFix Spearman's Correlation for Security\n")
      #print(cor(sec_n[,c(2,1)],method="spearman"))

      #cat("\nNonFix Spearman's Correlation for Stability Crash\n")
      #print(cor(stab_cn[,c(2,1)],method="spearman"))
      
      #cat("\nNonFix Spearman's Correlation for Stability Mem Addr\n")
      #print(cor(stab_mn[,c(2,1)],method="spearman"))
      
      release_filepaths_data <- dbGetQuery(con, "
        SELECT 
          release,
          sloc,
          num_regression_word_used,
	      num_compat_word_used,
	      num_security_word_used,
	      num_stabil_crash_word_used,
	      num_stabil_mem_address_word_used,
	      num_future_regression_bugs,
	      num_future_compat_bugs,
	      num_future_security_bugs,
	      num_future_stabil_crash_bugs,
	      num_future_stabil_mem_address_bugs
        FROM release_filepaths")
                
        # Split the data in relases
        r05 <- release_filepaths_data[ which(release_filepaths_data$release == "5.0"), -c(1)]
        r11 <- release_filepaths_data[ which(release_filepaths_data$release == '11.0'),-c(1)]
        r19 <- release_filepaths_data[ which(release_filepaths_data$release == '19.0'),-c(1)]
        r27 <- release_filepaths_data[ which(release_filepaths_data$release == '27.0'),-c(1)]
        r35 <- release_filepaths_data[ which(release_filepaths_data$release == '35.0'),-c(1)]
        cat("TECH WORD MODELING FOR RELEASE 05\n")
        release_modeling(r05)
        cat("TECH WORD MODELING FOR RELEASE 11\n")
        release_modeling(r11)
        cat("TECH WORD MODELING FOR RELEASE 19\n")
        release_modeling(r19)
        cat("TECH WORD MODELING FOR RELEASE 27\n")
        release_modeling(r27)
        cat("TECH WORD MODELING FOR RELEASE 35\n")
        release_modeling(r35)
        
        rm(release_filepaths_data,r05,r11,r19,r27,r35)
    EOR
    R.echo false, false
    puts "\n"
    rescue 
      puts "ERROR running glm model tests for Release #{title}"
    end
  end
end
