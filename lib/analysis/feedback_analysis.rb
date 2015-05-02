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
    R.eval <<-EOR
      dbDisconnect(con)
      dbUnloadDriver(drv)
    EOR
  end

  def r_modeling
    begin 

    # Set up libraries
    R.eval <<-EOR
              suppressMessages(library(ROCR, warn.conflicts = FALSE, quietly=TRUE))
              suppressMessages(library(bestglm, warn.conflicts = FALSE, quietly=TRUE))
              suppressMessages(library(lsr, warn.conflicts = FALSE, quietly=TRUE))
    EOR

    R.echo true, false
	
    #Add Modeling functions
    R.eval <<-EOR
      release_modeling <- function(release){
        options(warn=-1)

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
	fit_comp_words <- glm(formula = num_future_compat_bugs ~ sloc + num_compat_word_used, data = release, family = Gamma)
	fit_sec_words <- glm(formula = num_future_security_bugs ~ sloc + num_security_word_used, data = release, family = Gamma)
	fit_stab_crash_words <- glm(formula = num_future_stabil_crash_bugs ~ sloc + num_stabil_crash_word_used, data = release, family = Gamma)
	fit_stab_mem_words <- glm(formula = num_future_stabil_mem_address_bugs ~ sloc + num_stabil_mem_address_word_used, data = release, family = Gamma)

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
	  
	cat("\n# Summary for compatibility models\n")
	cat("fit_null_comp\n")
	print(summary(fit_null_comp))
	cat("fit_control_comp\n")
	print(summary(fit_control_comp))
	cat("fit_comp_words\n")
	print(summary(fit_comp_words))
	  
	cat("\n# Summary for security models\n")
	cat("fit_null_sec\n")
	print(summary(fit_null_sec))
	cat("fit_control_sec\n")
	print(summary(fit_control_sec))
	cat("fit_sec_words\n")
	print(summary(fit_sec_words))
	  
	cat("\n# Summary for stability_crash models\n")
	cat("fit_null_stab_crash\n")
	print(summary(fit_null_stab_crash))
	cat("fit_control_stab_crash\n")
	print(summary(fit_control_stab_crash))
	cat("fit_stab_crash_words\n")
	print(summary(fit_stab_crash_words))
	  
	cat("\n# Summary for stability_mem models\n")
	cat("fit_null_stab_mem\n")
	print(summary(fit_null_stab_mem))
	cat("fit_control_stab_mem\n")
	print(summary(fit_control_stab_mem))
	cat("fit_stab_mem_words\n")
	print(summary(fit_stab_mem_words))

	options(warn=0)
      }
    EOR
	
    #execute the modeling function on each release
    R.eval <<-EOR
      #Increase console width
      options("width"=250)
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
