# Define the functions
Dsquared <-function(obs = NULL, pred = NULL, model = NULL, adjust = FALSE) {
  # version 1.3 (3 Jan 2015)
  
  model.provided <- ifelse(is.null(model), FALSE, TRUE)
  
  if (model.provided) {
    if (!("glm" %in% class(model))) stop ("'model' must be of class 'glm'.")
    if (!is.null(pred)) message("Argument 'pred' ignored in favour of 'model'.")
    if (!is.null(obs)) message("Argument 'obs' ignored in favour of 'model'.")
    obs <- model$y
    pred <- model$fitted.values
    
  } else { # if model not provided
    if (is.null(obs) | is.null(pred)) stop("You must provide either 'obs' and 'pred', or a 'model' object of class 'glm'")
    if (length(obs) != length(pred)) stop ("'obs' and 'pred' must be of the same length (and in the same order).")
    if (!(obs %in% c(0, 1)) | pred < 0 | pred > 1) stop ("Sorry, 'obs' and 'pred' options currently only implemented for binomial GLMs (binary response variable with values 0 or 1) with logit link.")
    logit <- log(pred / (1 - pred))
    model <- glm(obs ~ logit, family = "binomial")
  }
  
  D2 <- (model$null.deviance - model$deviance) / model$null.deviance
  
  if (adjust) {
    if (!model.provided) return(message("Adjusted D-squared not calculated, as it requires a model object (with its number of parameters) rather than just 'obs' and 'pred' values."))
    
    n <- length(model$fitted.values)
    #p <- length(model$coefficients)
    p <- attributes(logLik(model))$df
    D2 <- 1 - ((n - 1) / (n - p)) * (1 - D2)
  }  # end if adj
  
  return (D2)
}

prediction_analysis<- function(fit,release.next){
  # Predict based on next release data.
  prediction <- predict(fit, newdata=release.next, type="response")
  
  # Use ROCR library calculate the performance.
  pred <- prediction(prediction,release.next$becomes_vulnerable)
  perf <- performance(pred, "prec", "rec")
  
  # Select the relevant values
  precision <- unlist(slot(perf, "y.values"))
  recall <- unlist(slot(perf, "x.values"))
  f_score = 2 * ((precision * recall)/(precision + recall))
  
  mean_precision= mean(precision, na.rm=TRUE)
  mean_recall = mean(recall, na.rm=TRUE)
  mean_f_score = mean(f_score, na.rm=TRUE)
  
  # Create ROC Curve, 
  # plot(perf, colorize=T)
  
  # Calculate the Area under the curve
  auc <- performance(pred,"auc")
  auc <- unlist(slot(auc, "y.values"))
  
  return (as.data.frame(cbind(mean_precision,mean_recall,mean_f_score,auc)))
}

# Removed comments from script, due to bug in R, the object can be larger that 10,000 bytes.
# Remove files where there were no bugs of any kind, or if it had no SLOC
# i.e. The subset must have at least on bug of ANY kind, and SLOC > 0
# Confirm if we need to remove the points with al variables are zero but outcome is TRUE.

# Normalize and center data, added one to the values to be able to calculate log to zero. log(1)=0

# Modeling (forward selection)
# Individual Models
# Category Based Models

# Display Results:

release_modeling <- function(release,release.next){
  options(warn=-1)



  release <- subset(release, (release$num_pre_features !=0 |
                              release$num_pre_compatibility_bugs !=0 | 
                              release$num_pre_regression_bugs !=0 | 
                              release$num_pre_security_bugs !=0 | 
                              release$num_pre_tests_fails_bugs != 0 | 
                              release$num_pre_stability_crash_bugs != 0 |
                              release$num_pre_build_bugs != 0 | 
                              release$becomes_vulnerable != FALSE) 
                            & release$sloc > 0)

  release.next <- subset(release.next, (release.next$num_pre_features !=0 |
                                        release.next$num_pre_compatibility_bugs !=0 | 
                                        release.next$num_pre_regression_bugs !=0 | 
                                        release.next$num_pre_security_bugs !=0 | 
                                        release.next$num_pre_tests_fails_bugs != 0 | 
                                        release.next$num_pre_stability_crash_bugs != 0 |
                                        release.next$num_pre_build_bugs != 0 | 
                                        release.next$becomes_vulnerable != FALSE) 
                                      & release.next$sloc > 0)

  release = cbind(as.data.frame(log(release[,-c(10)] + 1)), becomes_vulnerable = release$becomes_vulnerable)
  release.next = cbind(as.data.frame(log(release.next[,-c(10)] + 1)), becomes_vulnerable = release.next$becomes_vulnerable)

  fit_null <- glm(formula = becomes_vulnerable ~ 1, 
                  data = release, family = "binomial")

  fit_control <- glm(formula = becomes_vulnerable ~ sloc, 
                  data = release, family = "binomial")

  fit_all <- glm (formula= becomes_vulnerable ~ ., 
                  data = release, family = "binomial")

  fit_bugs <- glm (formula= becomes_vulnerable ~ sloc + num_pre_bugs, 
                  data = release, family = "binomial")

  
  fit_features <- glm (formula= becomes_vulnerable ~ sloc + num_pre_features, 
                       data = release, family = "binomial")

  fit_security <- glm (formula= becomes_vulnerable ~ sloc + num_pre_security_bugs, 
                       data = release, family = "binomial")

  fit_stability <- glm (formula= becomes_vulnerable ~ sloc + num_pre_stability_crash_bugs 
                        + num_pre_compatibility_bugs + num_pre_regression_bugs, 
                        data = release, family = "binomial")

  fit_build <- glm (formula= becomes_vulnerable ~ sloc + num_pre_build_bugs + num_pre_tests_fails_bugs, 
                        data = release, family = "binomial")     
  
  best_fit_AIC <- bestglm(release,family=binomial,IC = "AIC")

  
  cat("\nRelease Summary\n")
  print(summary(release))

  cat("\nSpearman's Correlation\n")
  print(cor(release[,-c(1,2,10)],method="spearman"))

  release_v <- release[ which(release$becomes_vulnerable == TRUE), ]
  release_n <- release[ which(release$becomes_vulnerable == FALSE), ]

  cat("\n% Vulnerable\n")
  print(cbind(Total = length(release[,1]),
              Neutral = length(release_n[,1]), 
              Vulnerable = length(release_v[,1]),
              Percentage = (length(release_v[,1])/length(release_n[,1]))*100))

  cat("\nWilcoxon:\n")
  print(wilcox.test(release_v$sloc, release_n$sloc, alternative="greater"))
  print(cbind(median_v = median(release_v$sloc, na.rm=TRUE),median_n = median(release_n$sloc, na.rm=TRUE)))
  
  print(wilcox.test(release_v$num_pre_bugs, release_n$num_pre_bugs, alternative="greater"))
  print(cbind(median_v = median(release_v$num_pre_bugs, na.rm=TRUE),median_n = median(release_n$num_pre_bugs, na.rm=TRUE)))
  
  print(wilcox.test(release_v$num_pre_features, release_n$num_pre_features, alternative="greater"))
  print(cbind(median_v = median(release_v$num_pre_features, na.rm=TRUE),median_n = median(release_n$num_pre_features, na.rm=TRUE)))
  
  print(wilcox.test(release_v$num_pre_compatibility_bugs, release_n$num_pre_compatibility_bugs, alternative="greater"))
  print(cbind(median_v = median(release_v$num_pre_compatibility_bugs, na.rm=TRUE),median_n = median(release_n$num_pre_compatibility_bugs, na.rm=TRUE)))
  
  print(wilcox.test(release_v$num_pre_regression_bugs, release_n$num_pre_regression_bugs, alternative="greater"))
  print(cbind(median_v = median(release_v$num_pre_regression_bugs, na.rm=TRUE),median_n = median(release_n$num_pre_regression_bugs, na.rm=TRUE)))
  
  print(wilcox.test(release_v$num_pre_security_bugs, release_n$num_pre_security_bugs, alternative="greater"))
  print(cbind(median_v = median(release_v$num_pre_security_bugs, na.rm=TRUE),median_n = median(release_n$num_pre_security_bugs, na.rm=TRUE)))
  
  print(wilcox.test(release_v$num_pre_tests_fails_bugs, release_n$num_pre_tests_fails_bugs, alternative="greater"))
  print(cbind(median_v = median(release_v$num_pre_tests_fails_bugs, na.rm=TRUE),median_n = median(release_n$num_pre_tests_fails_bugs, na.rm=TRUE)))
  
  print(wilcox.test(release_v$num_pre_stability_crash_bugs, release_n$num_pre_stability_crash_bugs, alternative="greater"))
  print(cbind(median_v = median(release_v$num_pre_stability_crash_bugs, na.rm=TRUE),median_n = median(release_n$num_pre_stability_crash_bugs, na.rm=TRUE)))
  
  print(wilcox.test(release_v$num_pre_build_bugs, release_n$num_pre_build_bugs, alternative="greater"))
  print(cbind(median_v = median(release_v$num_pre_build_bugs, na.rm=TRUE),median_n = median(release_n$num_pre_build_bugs, na.rm=TRUE)))

  cat("\nCohensD:\n")
  print(cbind(
    sloc = cohensD(release_v$sloc, release_n$sloc), 
    bugs = cohensD(release_v$num_pre_bugs, release_n$num_pre_bugs),
    features = cohensD(release_v$num_pre_features, release_n$num_pre_features),
    compatibility_bugs = cohensD(release_v$num_pre_compatibility_bugs, release_n$num_pre_compatibility_bugs),
    regression_bugs = cohensD(release_v$num_pre_regression_bugs, release_n$num_pre_regression_bugs),
    security_bugs = cohensD(release_v$num_pre_security_bugs, release_n$num_pre_security_bugs),
    tests_fails_bugs = cohensD(release_v$num_pre_tests_fails_bugs, release_n$num_pre_tests_fails_bugs),
    stability_crash_bugs = cohensD(release_v$num_pre_stability_crash_bugs, release_n$num_pre_stability_crash_bugs),
    build_bugs = cohensD(release_v$num_pre_build_bugs, release_n$num_pre_build_bugs)))
    
  cat("\n# Summary Control Models\n")
  cat("fit_null\n")
  print(summary(fit_null))
  cat("fit_control\n")
  print(summary(fit_control))
  cat("fit_all\n")
  print(summary(fit_all))
  cat("fit_bugs\n")
  print(summary(fit_bugs))

  cat("\n")
  cat("# Summary\n")
  cat("fit_security\n")
  print(summary(fit_security))
  cat("fit_features\n")
  print(summary(fit_features))
  cat("fit_stability\n")
  print(summary(fit_stability))
  cat("fit_build\n")
  print(summary(fit_build))
  cat("best_fit_AIC\n")
  print(summary(best_fit_AIC$BestModel))

  cat("\n")
  cat("# D^2 Analysys\n")
  cat("Control\n")
  cat("fit_control\n")
  print(Dsquared(model = fit_control))
  cat("For fit_all\n")
  print(Dsquared(model = fit_all))
  cat("For fit_bugs\n")
  print(Dsquared(model = fit_bugs))

  cat("\n")
  cat("# Categories\n")
  cat("fit_security\n")
  print(Dsquared(model = fit_security))
  cat("For fit_features\n")
  print(Dsquared(model = fit_features))
  cat("For fit_stability\n")
  print(Dsquared(model = fit_stability))
  cat("For fit_build\n")
  print(Dsquared(model = fit_build))
  cat("For best_fit_AIC\n")
  print(Dsquared(model = best_fit_AIC$BestModel))

  cat("\n")
  cat("# Prediction Analysis\n")
  cat("Control\n")
  cat("For fit_control\n")
  print(prediction_analysis(fit_control,release.next))
  cat("For fit_all\n")
  print(prediction_analysis(fit_all,release.next))
  cat("For fit_bugs\n")
  print(prediction_analysis(fit_bugs,release.next))


  cat("\n")
  cat("# Categories\n")
  cat("For fit_security\n")
  print(prediction_analysis(fit_security,release.next))
  cat("For fit_features\n")
  print(prediction_analysis(fit_features,release.next))
  cat("For fit_stability\n")
  print(prediction_analysis(fit_stability,release.next))
  cat("For fit_build\n")
  print(prediction_analysis(fit_build,release.next))
  cat("For best_fit_AIC\n")
  print(prediction_analysis(best_fit_AIC$BestModel,release.next))

  options(warn=0)
}