# Includes
source("includes.R")

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

release_modeling <- function(release, release.next){
  analyze.bugs(release, release.next)
  analyze.experience(release, release.next)
}

analyze.bugs <- function(release, release.next){
  options(warn=-1)

  # Remove files where there were no bugs of any kind, or if it had no SLOC
  # i.e. The subset must have at least on bug of ANY kind, and SLOC > 0
  release <- filter.dataset(release, filter.type = "bug")
  release.next <- filter.dataset(release.next, filter.type = "bug")

  # Display Results:
  cat("\nRelease Summary\n")
  print(summary(release))

  cat("\nSpearman's Correlation for bug metrics\n")
  print(round(cor(release[, c(4:11)], method = "spearman"), 4))

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
  print(cbind(mean_v = mean(release_v$sloc, na.rm=TRUE),mean_n = mean(release_n$sloc, na.rm=TRUE)))

  # For bug metrics
  cat("\nFor bug metrics:\n")
  print(wilcox.test(release_v$num_pre_bugs, release_n$num_pre_bugs, alternative="greater"))
  print(cbind(median_v = median(release_v$num_pre_bugs, na.rm=TRUE),median_n = median(release_n$num_pre_bugs, na.rm=TRUE)))
  print(cbind(mean_v = mean(release_v$num_pre_bugs, na.rm=TRUE),mean_n = mean(release_n$num_pre_bugs, na.rm=TRUE)))

  print(wilcox.test(release_v$num_pre_features, release_n$num_pre_features, alternative="greater"))
  print(cbind(median_v = median(release_v$num_pre_features, na.rm=TRUE),median_n = median(release_n$num_pre_features, na.rm=TRUE)))
  print(cbind(mean_v = mean(release_v$num_pre_features, na.rm=TRUE),mean_n = mean(release_n$num_pre_features, na.rm=TRUE)))

  print(wilcox.test(release_v$num_pre_compatibility_bugs, release_n$num_pre_compatibility_bugs, alternative="greater"))
  print(cbind(median_v = median(release_v$num_pre_compatibility_bugs, na.rm=TRUE),median_n = median(release_n$num_pre_compatibility_bugs, na.rm=TRUE)))
  print(cbind(mean_v = mean(release_v$num_pre_compatibility_bugs, na.rm=TRUE),mean_n = mean(release_n$num_pre_compatibility_bugs, na.rm=TRUE)))

  print(wilcox.test(release_v$num_pre_regression_bugs, release_n$num_pre_regression_bugs, alternative="greater"))
  print(cbind(median_v = median(release_v$num_pre_regression_bugs, na.rm=TRUE),median_n = median(release_n$num_pre_regression_bugs, na.rm=TRUE)))
  print(cbind(mean_v = mean(release_v$num_pre_regression_bugs, na.rm=TRUE),mean_n = mean(release_n$num_pre_regression_bugs, na.rm=TRUE)))

  print(wilcox.test(release_v$num_pre_security_bugs, release_n$num_pre_security_bugs, alternative="greater"))
  print(cbind(median_v = median(release_v$num_pre_security_bugs, na.rm=TRUE),median_n = median(release_n$num_pre_security_bugs, na.rm=TRUE)))
  print(cbind(mean_v = mean(release_v$num_pre_security_bugs, na.rm=TRUE),mean_n = mean(release_n$num_pre_security_bugs, na.rm=TRUE)))

  print(wilcox.test(release_v$num_pre_tests_fails_bugs, release_n$num_pre_tests_fails_bugs, alternative="greater"))
  print(cbind(median_v = median(release_v$num_pre_tests_fails_bugs, na.rm=TRUE),median_n = median(release_n$num_pre_tests_fails_bugs, na.rm=TRUE)))
  print(cbind(mean_v = mean(release_v$num_pre_tests_fails_bugs, na.rm=TRUE),mean_n = mean(release_n$num_pre_tests_fails_bugs, na.rm=TRUE)))

  print(wilcox.test(release_v$num_pre_stability_crash_bugs, release_n$num_pre_stability_crash_bugs, alternative="greater"))
  print(cbind(median_v = median(release_v$num_pre_stability_crash_bugs, na.rm=TRUE),median_n = median(release_n$num_pre_stability_crash_bugs, na.rm=TRUE)))
  print(cbind(mean_v = mean(release_v$num_pre_stability_crash_bugs, na.rm=TRUE),mean_n = mean(release_n$num_pre_stability_crash_bugs, na.rm=TRUE)))

  print(wilcox.test(release_v$num_pre_build_bugs, release_n$num_pre_build_bugs, alternative="greater"))
  print(cbind(median_v = median(release_v$num_pre_build_bugs, na.rm=TRUE),median_n = median(release_n$num_pre_build_bugs, na.rm=TRUE)))
  print(cbind(mean_v = mean(release_v$num_pre_build_bugs, na.rm=TRUE),mean_n = mean(release_n$num_pre_build_bugs, na.rm=TRUE)))

  # Normalize and center data, added one to the values to be able to calculate log to zero. log(1)=0
  release <- transform.dataset(release)
  release.next <- transform.dataset(release.next)

  release_v <- release[which(release$becomes_vulnerable == TRUE),]
  release_n <- release[which(release$becomes_vulnerable == FALSE),]

  cat("\nCohensD for Bug metrics:\n")
  print(cbind(
    sloc = cohensD(release_v$sloc, release_n$sloc),
    bugs = cohensD(release_v$num_pre_bugs, release_n$num_pre_bugs),
    features = cohensD(release_v$num_pre_features, release_n$num_pre_features),
    compatibility_bugs = cohensD(release_v$num_pre_compatibility_bugs, release_n$num_pre_compatibility_bugs),
    regression_bugs = cohensD(release_v$num_pre_regression_bugs, release_n$num_pre_regression_bugs),
    security_bugs = cohensD(release_v$num_pre_security_bugs, release_n$num_pre_security_bugs),
    tests_fails_bugs = cohensD(release_v$num_pre_tests_fails_bugs, release_n$num_pre_tests_fails_bugs),
    stability_crash_bugs = cohensD(release_v$num_pre_stability_crash_bugs, release_n$num_pre_stability_crash_bugs),
    build_bugs = cohensD(release_v$num_pre_build_bugs, release_n$num_pre_build_bugs)
  ))

  # Modeling (forward selection)
  # Individual Models
  fit_null <- glm(formula = becomes_vulnerable ~ 1,
                  data = release, family = "binomial")

  fit_control <- glm(formula = becomes_vulnerable ~ sloc,
                  data = release, family = "binomial")

  fit_bugs <- glm (formula= becomes_vulnerable ~ sloc + num_pre_bugs,
                  data = release, family = "binomial")

  # Category Based Models
  fit_features <- glm (formula= becomes_vulnerable ~ sloc + num_pre_features,
                       data = release, family = "binomial")

  fit_security <- glm (formula= becomes_vulnerable ~ sloc + num_pre_security_bugs,
                       data = release, family = "binomial")

  fit_stability <- glm (formula= becomes_vulnerable ~ sloc + num_pre_stability_crash_bugs
                        + num_pre_compatibility_bugs + num_pre_regression_bugs,
                        data = release, family = "binomial")

  fit_build <- glm (formula= becomes_vulnerable ~ sloc + num_pre_build_bugs + num_pre_tests_fails_bugs,
                        data = release, family = "binomial")

  #history models
  fit_vuln_to_vuln <- glm(formula = becomes_vulnerable ~ sloc + was_vulnerable,
                  data = release, family = "binomial")
  fit_bug_to_vuln <- glm(formula = becomes_vulnerable ~ sloc + was_buggy,
                  data = release, family = "binomial")
  fit_bug_to_bug <- glm(formula = becomes_buggy ~ sloc + was_buggy,
                  data = release, family = "binomial")

  cat("\n# Summary Control Models\n")
  cat("fit_null\n")
  print(summary(fit_null))
  cat("fit_control\n")
  print(summary(fit_control))
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

  cat("\n")
  cat("# Summary History Models\n")
  cat("fit_vuln_to_vuln\n")
  print(summary(fit_vuln_to_vuln))
  cat("fit_bug_to_vuln\n")
  print(summary(fit_bug_to_vuln))
  cat("fit_bug_to_bug\n")
  print(summary(fit_bug_to_bug))

  cat("\n")
  cat("# D^2 Analysys\n")
  cat("Control\n")
  cat("fit_control\n")
  print(Dsquared(model = fit_control))
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

  cat("\n")
  cat("# Summary History Models\n")
  cat("fit_vuln_to_vuln\n")
  print(Dsquared(model = fit_vuln_to_vuln))
  cat("fit_bug_to_vuln\n")
  print(Dsquared(model = fit_bug_to_vuln))
  cat("fit_bug_to_bug\n")
  print(Dsquared(model = fit_bug_to_bug))


  cat("\n")
  cat("# Prediction Analysis\n")
  cat("Control\n")
  cat("For fit_control\n")
  print(prediction_analysis(fit_control,release.next))
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

  cat("\n")
  cat("# Summary History Models\n")
  cat("fit_vuln_to_vuln\n")
  print(prediction_analysis(fit_vuln_to_vuln,release.next))
  cat("fit_bug_to_vuln\n")
  print(prediction_analysis(fit_bug_to_vuln,release.next))
  cat("fit_bug_to_bug\n")
  print(prediction_analysis(fit_bug_to_bug,release.next))

  options(warn=0)
}

analyze.experience <- function(release, release.next){
  options(warn=-1)


  # Remove files where there were no bugs of any kind, or if it had no SLOC
  # i.e. The subset must have at least on bug of ANY kind, and SLOC > 0
  release <- filter.dataset(release, filter.type = "experience")
  release.next <- filter.dataset(release.next, filter.type = "experience")

  # Display Results:
  cat("\nRelease Summary\n")
  print(summary(release))

  cat("\nSpearman's Correlation for experience metrics\n")
  print(cor(release[,c(14:19)],method="spearman", use = "complete"))

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
  print(cbind(mean_v = mean(release_v$sloc, na.rm=TRUE),mean_n = mean(release_n$sloc, na.rm=TRUE)))

  # For experience metrics
  cat("\nFor experience metrics:\n")
  print(wilcox.test(release_v$avg_security_experienced_participants, release_n$avg_security_experienced_participants, alternative="greater"))
  print(cbind(median_v = median(release_v$avg_security_experienced_participants, na.rm=TRUE),median_n = median(release_n$avg_security_experienced_participants, na.rm=TRUE)))
  print(cbind(mean_v = mean(release_v$avg_security_experienced_participants, na.rm=TRUE),mean_n = mean(release_n$avg_security_experienced_participants, na.rm=TRUE)))

  print(wilcox.test(release_v$avg_bug_security_experienced_participants, release_n$avg_bug_security_experienced_participants, alternative="greater"))
  print(cbind(median_v = median(release_v$avg_bug_security_experienced_participants, na.rm=TRUE),median_n = median(release_n$avg_bug_security_experienced_participants, na.rm=TRUE)))
  print(cbind(mean_v = mean(release_v$avg_bug_security_experienced_participants, na.rm=TRUE),mean_n = mean(release_n$avg_bug_security_experienced_participants, na.rm=TRUE)))

  print(wilcox.test(release_v$avg_stability_experienced_participants, release_n$avg_stability_experienced_participants, alternative="greater"))
  print(cbind(median_v = median(release_v$avg_stability_experienced_participants, na.rm=TRUE),median_n = median(release_n$avg_stability_experienced_participants, na.rm=TRUE)))
  print(cbind(mean_v = mean(release_v$avg_stability_experienced_participants, na.rm=TRUE),mean_n = mean(release_n$avg_stability_experienced_participants, na.rm=TRUE)))

  print(wilcox.test(release_v$avg_build_experienced_participants, release_n$avg_build_experienced_participants, alternative="greater"))
  print(cbind(median_v = median(release_v$avg_build_experienced_participants, na.rm=TRUE),median_n = median(release_n$avg_build_experienced_participants, na.rm=TRUE)))
  print(cbind(mean_v = mean(release_v$avg_build_experienced_participants, na.rm=TRUE),mean_n = mean(release_n$avg_build_experienced_participants, na.rm=TRUE)))

  print(wilcox.test(release_v$avg_test_fail_experienced_participants, release_n$avg_test_fail_experienced_participants, alternative="greater"))
  print(cbind(median_v = median(release_v$avg_test_fail_experienced_participants, na.rm=TRUE),median_n = median(release_n$avg_test_fail_experienced_participants, na.rm=TRUE)))
  print(cbind(mean_v = mean(release_v$avg_test_fail_experienced_participants, na.rm=TRUE),mean_n = mean(release_n$avg_test_fail_experienced_participants, na.rm=TRUE)))

  print(wilcox.test(release_v$avg_compatibility_experienced_participants, release_n$avg_compatibility_experienced_participants, alternative="greater"))
  print(cbind(median_v = median(release_v$avg_compatibility_experienced_participants, na.rm=TRUE),median_n = median(release_n$avg_compatibility_experienced_participants, na.rm=TRUE)))
  print(cbind(mean_v = mean(release_v$avg_compatibility_experienced_participants, na.rm=TRUE),mean_n = mean(release_n$avg_compatibility_experienced_participants, na.rm=TRUE)))

  cat("\nCohensD for Experience metrics:\n")
  print(cbind(
    avg_security_experienced_participants = cohensD(release_v$avg_security_experienced_participants, release_n$avg_security_experienced_participants),
    avg_bug_security_experienced_participants = cohensD(release_v$avg_bug_security_experienced_participants, release_n$avg_bug_security_experienced_participants),
    avg_stability_experienced_participants = cohensD(release_v$avg_stability_experienced_participants, release_n$avg_stability_experienced_participants),
    avg_build_experienced_participants = cohensD(release_v$avg_build_experienced_participants, release_n$avg_build_experienced_participants),
    avg_test_fail_experienced_participants = cohensD(release_v$avg_test_fail_experienced_participants, release_n$avg_test_fail_experienced_participants),
    avg_compatibility_experienced_participants = cohensD(release_v$avg_compatibility_experienced_participants, release_n$avg_compatibility_experienced_participants)
  ))

  # Modeling (forward selection)
  # Individual Models
  fit_null <- glm(formula = becomes_vulnerable ~ 1,
                  data = release, family = "binomial")

  fit_control <- glm(formula = becomes_vulnerable ~ sloc,
                  data = release, family = "binomial")

  # Experience Based Models
  fit_security_experienced <- glm (formula= becomes_vulnerable ~ sloc + avg_security_experienced_participants,
                        data = release, family = "binomial")

  fit_bug_security_experienced <- glm (formula= becomes_vulnerable ~ sloc + avg_bug_security_experienced_participants,
                        data = release, family = "binomial")

  fit_stability_experienced <- glm (formula= becomes_vulnerable ~ sloc + avg_stability_experienced_participants,
                        data = release, family = "binomial")

  fit_build_experienced <- glm (formula= becomes_vulnerable ~ sloc + avg_build_experienced_participants,
                        data = release, family = "binomial")

  fit_test_fail_experienced <- glm (formula= becomes_vulnerable ~ sloc + avg_test_fail_experienced_participants,
                        data = release, family = "binomial")

  fit_compatibility_experienced <- glm (formula= becomes_vulnerable ~ sloc + avg_compatibility_experienced_participants,
                        data = release, family = "binomial")

  cat("\n# Summary Control Models\n")
  cat("fit_null\n")
  print(summary(fit_null))
  cat("fit_control\n")
  print(summary(fit_control))

  cat("\n")
  cat("# Summary Experience Models\n")
  cat("fit_security_experienced\n")
  print(summary(fit_security_experienced))
  cat("fit_bug_security_experienced\n")
  print(summary(fit_bug_security_experienced))
  cat("fit_stability_experienced\n")
  print(summary(fit_stability_experienced))
  cat("fit_build_experienced\n")
  print(summary(fit_build_experienced))
  cat("fit_test_fail_experienced\n")
  print(summary(fit_test_fail_experienced))
  cat("fit_compatibility_experienced\n")
  print(summary(fit_compatibility_experienced))

  cat("\n")
  cat("# D^2 Analysys\n")
  cat("Control\n")
  cat("fit_control\n")
  print(Dsquared(model = fit_control))


  cat("\n")
  cat("# Summary Experience Models\n")
  cat("fit_security_experienced\n")
  print(Dsquared(model = fit_security_experienced))
  cat("fit_bug_security_experienced\n")
  print(Dsquared(model = fit_bug_security_experienced))
  cat("fit_stability_experienced\n")
  print(Dsquared(model = fit_stability_experienced))
  cat("fit_build_experienced\n")
  print(Dsquared(model = fit_build_experienced))
  cat("fit_test_fail_experienced\n")
  print(Dsquared(model = fit_test_fail_experienced))
  cat("fit_compatibility_experienced\n")
  print(Dsquared(model = fit_compatibility_experienced))

  cat("\n")
  cat("# Prediction Analysis\n")
  cat("Control\n")
  cat("For fit_control\n")
  print(prediction_analysis(fit_control,release.next))

  cat("\n")
  cat("# Summary Experience Models\n")
  cat("fit_security_experienced\n")
  print(prediction_analysis(fit_security_experienced,release.next))
  cat("fit_bug_security_experienced\n")
  print(prediction_analysis(fit_bug_security_experienced,release.next))
  cat("fit_stability_experienced\n")
  print(prediction_analysis(fit_stability_experienced,release.next))
  cat("fit_build_experienced\n")
  print(prediction_analysis(fit_build_experienced,release.next))
  cat("fit_test_fail_experienced\n")
  print(prediction_analysis(fit_test_fail_experienced,release.next))
  cat("fit_compatibility_experienced\n")
  print(prediction_analysis(fit_compatibility_experienced,release.next))

  options(warn=0)
}

model.overall <- function(dataset, switch, k, n){
  model.bugs.overall(dataset, switch, k, n)
  model.experience.overall(dataset, switch, k, n)
}

model.bugs.overall <- function(dataset, switch, k, n){
  # Data Filtering and Tranformation
  dataset <- filter.dataset(dataset, filter.type = "bug")
  dataset <- transform.dataset(dataset)

  # Logistic Regression Modeling

  # Control
  fit.formula = formula(becomes_vulnerable ~ release + sloc)
  ### Model Summary
  fit.control <- build.model(fit.formula, dataset)
  ### Model Performance
  fit.control.performance <- run.kfolds(fit.formula, dataset, switch, k, n)

  # Bugs
  fit.formula = formula(
    becomes_vulnerable ~ release + sloc + num_pre_bugs
  )
  fit.bugs <- build.model(fit.formula, dataset)
  fit.bugs.performance <- run.kfolds(fit.formula, dataset, switch, k, n)

  ## Bugs: Build and Test Failure
  fit.formula = formula(
    becomes_vulnerable ~ release + sloc + num_pre_build_bugs +
    num_pre_tests_fails_bugs
  )
  fit.build <- build.model(fit.formula, dataset)
  fit.build.performance <- run.kfolds(fit.formula, dataset, switch, k, n)

  ## Bugs: Features
  fit.formula <- formula(
    becomes_vulnerable ~ release + sloc + num_pre_features
  )
  fit.features <- build.model(fit.formula, dataset)
  fit.features.performance <- run.kfolds(fit.formula, dataset, switch, k, n)

  ## Bugs: Security
  fit.formula <- formula(
    becomes_vulnerable ~ release + sloc + num_pre_security_bugs
  )
  fit.security <- build.model(fit.formula, dataset)
  fit.security.performance <- run.kfolds(fit.formula, dataset, switch, k, n)

  ## Bugs: Stability
  fit.formula <- formula(
    becomes_vulnerable ~ release + sloc + num_pre_stability_crash_bugs +
    num_pre_compatibility_bugs + num_pre_regression_bugs
  )
  fit.stability <- build.model(fit.formula, dataset)
  fit.stability.performance <- run.kfolds(fit.formula, dataset, switch, k, n)

  cat("############################\n")
  cat("CONTROL\n")
  cat("############################\n")

  cat("##########  SUMMARY\n")
  print(summary(fit.control))
  cat("##########  PERFORMANCE\n")
  print(data.frame(fit.control.performance))
  cat("##########  DEVIANCE\n")
  print(Dsquared(model = fit.control))
  cat("\n#################################################\n")

  cat("############################\n")
  cat("BUG MODELS\n")
  cat("############################\n")

  cat("##########  SUMMARY\n")
  print.summary(fit.bugs)
  cat("##########  PERFORMANCE\n")
  print(data.frame(fit.bugs.performance))
  cat("##########  DEVIANCE\n")
  print(Dsquared(model = fit.bugs))
  cat("\n#################################################\n")

  cat("##########  SUMMARY\n")
  print.summary(fit.build)
  cat("##########  PERFORMANCE\n")
  print(data.frame(fit.build.performance))
  cat("##########  DEVIANCE\n")
  print(Dsquared(model = fit.build))
  cat("\n#################################################\n")

  cat("##########  SUMMARY\n")
  print.summary(fit.features)
  cat("##########  PERFORMANCE\n")
  print(data.frame(fit.features.performance))
  cat("##########  DEVIANCE\n")
  print(Dsquared(model = fit.features))
  cat("\n#################################################\n")

  cat("##########  SUMMARY\n")
  print.summary(fit.security)
  cat("##########  PERFORMANCE\n")
  print(data.frame(fit.security.performance))
  cat("##########  DEVIANCE\n")
  print(Dsquared(model = fit.security))
  cat("\n#################################################\n")

  cat("##########  SUMMARY\n")
  print.summary(fit.stability)
  cat("##########  PERFORMANCE\n")
  print(data.frame(fit.stability.performance))
  cat("##########  DEVIANCE\n")
  print(Dsquared(model = fit.stability))
}

model.experience.overall <- function(dataset, switch, k, n){
  # Data Filtering
  dataset <- filter.dataset(dataset, filter.type = "experience")

  # Logistic Regression Modeling

  # Control
  fit.formula = formula(becomes_vulnerable ~ release + sloc)
  ### Model Summary
  fit.control <- build.model(fit.formula, dataset)
  ### Model Performance
  fit.control.performance <- run.kfolds(fit.formula, dataset, switch, k, n)

  ## Build Experience
  fit.formula <- formula(
    becomes_vulnerable ~ release + sloc + avg_build_experienced_participants
  )
  fit.build <- build.model(fit.formula, dataset)
  fit.build.performance <- run.kfolds(fit.formula, dataset, switch, k, n)

  ## Compatibility Experience
  fit.formula = formula(
    becomes_vulnerable ~ release + sloc +
    avg_compatibility_experienced_participants
  )
  fit.compatibility <- build.model(fit.formula, dataset)
  fit.compatibility.performance <- run.kfolds(
    fit.formula, dataset, switch, k, n
  )

  ## Security Experience
  fit.formula <- formula(
    becomes_vulnerable ~ release + sloc +
    avg_security_experienced_participants
  )
  fit.security <- build.model(fit.formula, dataset)
  fit.security.performance <- run.kfolds(fit.formula, dataset, switch, k, n)

  ## Security Bug Experience
  fit.formula <- formula(
    becomes_vulnerable ~ release + sloc +
    avg_bug_security_experienced_participants
  )
  fit.securitybug <- build.model(fit.formula, dataset)
  fit.securitybug.performance <- run.kfolds(fit.formula, dataset, switch, k, n)

  ## Test Failure Experience
  fit.formula <- formula(
    becomes_vulnerable ~ release + sloc +
    avg_test_fail_experienced_participants
  )
  fit.testfail <- build.model(formula = fit.formula, dataset)
  fit.testfail.performance <- run.kfolds(fit.formula, dataset, switch, k, n)

  ## Stability Experience
  fit.formula <- formula(
    becomes_vulnerable ~ release + sloc +
    avg_stability_experienced_participants
  )
  fit.stability <- build.model(formula = fit.formula, dataset)
  fit.stability.performance <- run.kfolds(fit.formula, dataset, switch, k, n)

  cat("############################\n")
  cat("CONTROL\n")
  cat("############################\n")

  cat("##########  SUMMARY\n")
  print(summary(fit.control))
  cat("##########  PERFORMANCE\n")
  print(data.frame(fit.control.performance))
  cat("##########  DEVIANCE\n")
  print(Dsquared(model = fit.control))
  cat("\n#################################################\n")

  cat("############################\n")
  cat("EXPERIENCE MODELS\n")
  cat("############################\n")

  cat("##########  SUMMARY\n")
  print.summary(fit.build)
  cat("##########  PERFORMANCE\n")
  print(data.frame(fit.build.performance))
  cat("##########  DEVIANCE\n")
  print(Dsquared(model = fit.build))
  cat("\n#################################################\n")

  cat("##########  SUMMARY\n")
  print.summary(fit.compatibility)
  cat("##########  PERFORMANCE\n")
  print(data.frame(fit.compatibility.performance))
  cat("##########  DEVIANCE\n")
  print(Dsquared(model = fit.compatibility))
  cat("\n#################################################\n")

  cat("##########  SUMMARY\n")
  print.summary(fit.security)
  cat("##########  PERFORMANCE\n")
  print(data.frame(fit.security.performance))
  cat("##########  DEVIANCE\n")
  print(Dsquared(model = fit.security))
  cat("\n#################################################\n")

  cat("##########  SUMMARY\n")
  print.summary(fit.securitybug)
  cat("##########  PERFORMANCE\n")
  print(data.frame(fit.securitybug.performance))
  cat("##########  DEVIANCE\n")
  print(Dsquared(model = fit.securitybug))
  cat("\n#################################################\n")

  cat("##########  SUMMARY\n")
  print.summary(fit.testfail)
  cat("##########  PERFORMANCE\n")
  print(data.frame(fit.testfail.performance))
  cat("##########  DEVIANCE\n")
  print(Dsquared(model = fit.testfail))
  cat("\n#################################################\n")

  cat("##########  SUMMARY\n")
  print.summary(fit.stability)
  cat("##########  PERFORMANCE\n")
  print(data.frame(fit.stability.performance))
  cat("##########  DEVIANCE\n")
  print(Dsquared(model = fit.stability))
  cat("\n#################################################\n")
}
