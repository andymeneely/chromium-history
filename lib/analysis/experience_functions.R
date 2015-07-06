prediction_analysis<- function(fit, release.next){
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

release_modeling <- function(release,release.next){
  options(warn=-1)

  # Log-transform and center data, added one to the values to be able to calculate log to zero. log(1)=0
  release = cbind(as.data.frame(log(release[,sapply(release, is.numeric)] + 1)),
                  becomes_vulnerable = release$becomes_vulnerable)
  release.next = cbind(as.data.frame(log(release.next[,sapply(release.next, is.numeric)] + 1)),
                  becomes_vulnerable = release.next$becomes_vulnerable)

  # Modeling (forward selection)
  # Individual Models
  fit_null <- glm(formula = becomes_vulnerable ~ 1,
                  data = release, family = "binomial")

  fit_control <- glm(formula = becomes_vulnerable ~ sloc,
                  data = release, family = "binomial")

  fit_experience <- glm(formula = becomes_vulnerable ~ sloc
                        + num_participants
                        + avg_sheriff_hours
                        + perc_security_experienced_participants + perc_bug_security_experienced_participants + perc_build_experienced_participants + perc_test_fail_experienced_participants + perc_compatibility_experienced_participants,
                        data = release, family = "binomial")

  fit_bystander <- glm(formula = becomes_vulnerable ~ sloc
                        + perc_fast_reviews + perc_three_more_reviewers,
                  data = release, family = "binomial")

  fit_ownership <- glm (formula= becomes_vulnerable ~ sloc
                    + num_owners + avg_time_to_ownership + avg_ownership_distance,
                  data = release, family = "binomial")

  fit_one_per <- glm (formula= becomes_vulnerable ~ sloc
                    + perc_fast_reviews
                    + avg_sheriff_hours
                    + avg_ownership_distance
                    + num_participants
                    + perc_security_experienced_participants,
                  data = release, family = "binomial")

  fit_all <- glm (formula= becomes_vulnerable ~ sloc
                    + perc_fast_reviews + perc_three_more_reviewers
                    + avg_sheriff_hours
                    + num_owners + avg_time_to_ownership + avg_ownership_distance
                    + num_participants
                    + perc_security_experienced_participants + perc_bug_security_experienced_participants + perc_build_experienced_participants + perc_test_fail_experienced_participants + perc_compatibility_experienced_participants,
                  data = release, family = "binomial")


  #best_fit_AIC <- bestglm(release,family=binomial,IC = "AIC")


  # release_v <- release[ which(release$becomes_vulnerable == TRUE), ]
  # release_n <- release[ which(release$becomes_vulnerable == FALSE), ]

  # cat("\nCohensD:\n")
  # print(cbind(
  #   sloc = cohensD(release_v$sloc, release_n$sloc),
  #   bugs = cohensD(release_v$num_pre_bugs, release_n$num_pre_bugs),
  #   features = cohensD(release_v$num_pre_features, release_n$num_pre_features),
  #   compatibility_bugs = cohensD(release_v$num_pre_compatibility_bugs, release_n$num_pre_compatibility_bugs),
  #   regression_bugs = cohensD(release_v$num_pre_regression_bugs, release_n$num_pre_regression_bugs),
  #   security_bugs = cohensD(release_v$num_pre_security_bugs, release_n$num_pre_security_bugs),
  #   tests_fails_bugs = cohensD(release_v$num_pre_tests_fails_bugs, release_n$num_pre_tests_fails_bugs),
  #   stability_crash_bugs = cohensD(release_v$num_pre_stability_crash_bugs, release_n$num_pre_stability_crash_bugs),
  #   build_bugs = cohensD(release_v$num_pre_build_bugs, release_n$num_pre_build_bugs)))

  cat("\n# Summary Control Models\n")
  cat("fit_null\n")
  print(summary(fit_null))
  cat("fit_control\n")
  print(summary(fit_control))
  cat("fit_experience\n")
  print(summary(fit_experience))
  cat("fit_bystander\n")
  print(summary(fit_bystander))
  cat("fit_ownership\n")
  print(summary(fit_ownership))
  cat("fit_one_per\n")
  print(summary(fit_one_per ))
  cat("fit_all\n")
  print(summary(fit_all))

  # cat("\n")
  # cat("# D^2 Analysys\n")
  # cat("Control\n")
  # cat("fit_control\n")
  # print(Dsquared(model = fit_control))
  # cat("For fit_all\n")
  # print(Dsquared(model = fit_all))
  # cat("For fit_bugs\n")
  # print(Dsquared(model = fit_bugs))

  # cat("\n")
  # cat("# Categories\n")
  # cat("fit_security\n")
  # print(Dsquared(model = fit_security))
  # cat("For fit_features\n")
  # print(Dsquared(model = fit_features))
  # cat("For fit_stability\n")
  # print(Dsquared(model = fit_stability))
  # cat("For fit_build\n")
  # print(Dsquared(model = fit_build))
  #cat("For best_fit_AIC\n")
  #rint(Dsquared(model = best_fit_AIC$BestModel))

  # cat("\n")
  # cat("# Summary History Models\n")
  # # cat("fit_vuln_to_vuln\n")
  # # print(Dsquared(model = fit_vuln_to_vuln))
  # # cat("fit_bug_to_vuln\n")
  # # print(Dsquared(model = fit_bug_to_vuln))
  # # cat("fit_bug_to_bug\n")
  # # print(Dsquared(model = fit_bug_to_bug))

  cat("\n")
  cat("# AIC Improvements\n")
  aics <- data.frame( "name" = character(), "aic" = integer(), "PercOfControl" = integer(), stringsAsFactors=FALSE )
  aics[ nrow(aics) + 1, ] <- c( "fit_control", extractAIC(fit_control)[2], extractAIC(fit_control)[2] )
  aics[ nrow(aics) + 1, ] <- c( "fit_experience", extractAIC(fit_experience)[2], extractAIC(fit_experience)[2] / extractAIC(fit_control)[2])
  aics[ nrow(aics) + 1, ] <- c( "fit_bystander",  extractAIC(fit_bystander)[2],  extractAIC(fit_bystander)[2] / extractAIC(fit_control)[2])
  aics[ nrow(aics) + 1, ] <- c( "fit_ownership",  extractAIC(fit_ownership)[2],  extractAIC(fit_ownership)[2] / extractAIC(fit_control)[2])
  aics[ nrow(aics) + 1, ] <- c( "fit_one_per", extractAIC(fit_one_per)[2],       extractAIC(fit_one_per)[2] / extractAIC(fit_control)[2])
  aics[ nrow(aics) + 1, ] <- c( "fit_all",     extractAIC(fit_all)[2],           extractAIC(fit_all)[2] / extractAIC(fit_control)[2] )
  print(aics)

  cat("\n")
  cat("# Prediction Analysis\n")
  cat("For fit_control\n")
  print(prediction_analysis(fit_control,release.next))
  cat("For fit_experience\n")
  print(prediction_analysis(fit_experience,release.next))
  cat("For fit_bystander\n")
  print(prediction_analysis(fit_bystander,release.next))
  cat("For fit_ownership\n")
  print(prediction_analysis(fit_ownership,release.next))
  cat("For fit_one_per\n")
  print(prediction_analysis(fit_one_per,release.next))
  cat("For fit_all\n")
  print(prediction_analysis(fit_all,release.next))

  options(warn=0)
}
