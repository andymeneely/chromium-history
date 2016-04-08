init.libraries <- function(){
  suppressPackageStartupMessages(library("DBI"))
  suppressPackageStartupMessages(library("ggplot2"))
}

get.db.connection <- function(db.settings){
  connection <- db.connect(
    provider = db.settings$default$provider,
    host = db.settings$default$host, port = db.settings$default$port,
    user = db.settings$default$user, password = db.settings$default$password,
    dbname = db.settings$default$dbname
  )
  return(connection)
}

db.connect <- function(provider, host, port, user, password, dbname){
  connection <- NULL

  if(provider == "PostgreSQL"){
    library("RPostgreSQL")
  } else if(provider == "MySQL"){
    library("RMySQL")
  } else {
    stop(sprintf("Database provider %s not supported.", provider))
  }

  connection <- dbConnect(
    dbDriver(provider),
    host = host, port = port, user = user, password = password, dbname = dbname
  )
  return(connection)
}

db.disconnect <- function(connection){
  return(dbDisconnect(connection))
}

db.get.data <- function(connection, query){
  return(dbGetQuery(connection, query))
}

build.model <- function(formula, dataset){
  model <- glm(formula = formula, data = dataset, family = "binomial")
  return(model)
}

print.summary <- function(model){
  print(model$formula)
  print(summary(model))
}

compute.fmeasure <- function(precision, recall, beta = 1){
    return(
      ((1 + beta ^ 2) * precision * recall)
      /
        ((beta ^ 2 * precision) + recall)
    )
}

aggregate.performance <- function(measures){
  precision <- numeric(length(measures))
  recall <- numeric(length(measures))
  auc <- numeric(length(measures))

  index <- 1
  for(measure in measures){
    precision[index] <- measure$mean_precision
    recall[index] <- measure$mean_recall
    auc[index] <- measure$auc
    index <- index + 1
  }

  avg_precision <- mean(precision)
  avg_recall <- mean(recall)
  fmeasure <- compute.fmeasure(avg_precision, avg_recall)
  avg_auc <- mean(auc)

  performance <- list(
    "avg_precision" = avg_precision, "avg_recall" = avg_recall,
    "fmeasure" = fmeasure, "avg_auc" = avg_auc
  )

  return(performance)
}

get.kfolds <- function(dataset, switch, k){
  # Split the population into Neutral and Vulnerable sub-populations
  neut <- dataset[dataset[switch] == FALSE,]
  vuln <- dataset[dataset[switch] == TRUE,]
  # Count the number of Neutral and Vulnerable observations per fold
  #   The proportion of neutral and vulnerable observations must be kept the
  #   same in each fold
  fold.num.neut <- ceiling(nrow(neut) / k)
  fold.num.vuln <- ceiling(nrow(vuln) / k)
  # Randomization
  random.neut.indices <- sample(1:nrow(neut))
  random.vuln.indices <- sample(1:nrow(vuln))

  # Sub-sample indices
  fold.neut.beg <- 1
  fold.neut.end <- fold.num.neut
  fold.vuln.beg <- 1
  fold.vuln.end <- fold.num.vuln

  folds <- list()
  for(index in 1:k){
    folds[[index]] <- rbind(
      neut[random.neut.indices[fold.neut.beg:fold.neut.end],],
      vuln[random.vuln.indices[fold.vuln.beg:fold.vuln.end],]
    )

    fold.neut.beg <- fold.neut.end + 1
    fold.neut.end <- min(nrow(neut), (fold.neut.end + fold.num.neut))
    fold.vuln.beg <- fold.vuln.end + 1
    fold.vuln.end <- min(nrow(vuln), (fold.vuln.end + fold.num.vuln))
  }

  return(folds)
}

split.kfolds <- function(folds, testing.fold){
  training <- data.frame()
  testing <- NA
  for(index in 1:length(folds)){
    if(index == testing.fold){
      testing <- folds[[index]]
      next
    }
    training <- rbind(training, folds[[index]]) 
  }
  return(list("training" = training, "testing" = testing))
}

run.kfolds <- function(formula, dataset, switch, k, n){
  performance <- vector(mode = "list", length = k * n)
  index <- 1
  for(iteration in 1:n){
    folds <- get.kfolds(dataset, switch, k)
    for(fold in 1:k){
      fold.dataset <- split.kfolds(folds, testing.fold = fold)
      model <- build.model(formula, fold.dataset$training)
      performance[[index]] <- prediction_analysis(model, fold.dataset$testing)
      index <- index + 1
    }
  }

  return(aggregate.performance(performance))
}

filter.dataset <- function(dataset){
  dataset <- subset(dataset,
    (
      dataset$num_pre_features !=0 |
      dataset$num_pre_compatibility_bugs !=0 |
      dataset$num_pre_regression_bugs !=0 |
      dataset$num_pre_security_bugs !=0 |
      dataset$num_pre_tests_fails_bugs != 0 |
      dataset$num_pre_stability_crash_bugs != 0 |
      dataset$num_pre_build_bugs != 0 |
      dataset$becomes_vulnerable != FALSE
    ) & dataset$sloc > 0
  )
  return(dataset)
}

transform.dataset <- function(dataset){
  numeric.columns <- sapply(dataset, is.numeric)
  dataset <- cbind(
    log(dataset[, numeric.columns] + 1),
    dataset[,!numeric.columns]
  )
  return(dataset)
}
