# Clear
rm(list = ls())
cat("\014")

# Check for Database Connection Settings
if(!file.exists("db.settings.R")){
  stop(sprintf("db.settings.R file not found."))
}

# Include Libraries
source("db.settings.R")
source("includes.R")

# Initialize Libraries
init.libraries()

# ggplot Theme
plot.theme <-
  theme_bw() +
  theme(
    plot.title = element_text(
      size = 14, face = "bold", margin = margin(5,0,15,0)
    ),
    axis.text.x = element_text(size = 10, angle = 50, vjust = 1, hjust = 1),
    axis.title.x = element_text(face = "bold", margin = margin(15,0,5,0)),
    axis.text.y = element_text(size = 10),
    axis.title.y = element_text(face = "bold", margin = margin(0,15,0,5)),
    strip.text.x = element_text(size = 10, face = "bold"),
    legend.position = "bottom"
  )

###################################################################################
## Box and Density Plots
###################################################################################

#### Query Data
query <- "
  SELECT release,
    -- Switch
    becomes_vulnerable,
    -- Control Metric
    sloc,
    -- Bug Metrics: Reference
    num_pre_bugs,
    -- Bug Metrics: Categories
    num_pre_build_bugs,
    num_pre_tests_fails_bugs,
    num_pre_features,
    num_pre_security_bugs,
    num_pre_stability_crash_bugs,
    num_pre_compatibility_bugs,
    num_pre_regression_bugs,
    -- Review Experience Metrics
    avg_build_experienced_participants,
    avg_compatibility_experienced_participants,
    avg_security_experienced_participants,
    avg_bug_security_experienced_participants,
    avg_stability_experienced_participants,
    avg_test_fail_experienced_participants
  FROM release_filepaths
  ORDER BY CAST(release AS NUMERIC) ASC
"

db.connection <- get.db.connection(db.settings)
dataset <- dbGetQuery(db.connection, query)
dbDisconnect(db.connection)

##########################################
### Bug Metrics
##########################################

### Reference
#### Export Resolution: 400 x 460
ggplot(dataset, aes(x = becomes_vulnerable, y = num_pre_bugs)) +
  geom_boxplot(
    aes(fill = factor(becomes_vulnerable, levels = c(TRUE, FALSE)))
  ) +
  scale_y_log10() +
  scale_fill_manual(
    values=c("#bfbfbf", "#ffffff"), name="Vulnerable",
    labels=c("TRUE" = "Yes", "FALSE" = "No")
  ) +
  labs(title = NULL, x = NULL, y = "Num. of Pre-release Bugs (Log Scale)") +
  plot.theme +
  theme(axis.text.x = element_blank())

### Prepare Plotting Data Set
COLUMN.LABELS <- list(
  "num_pre_build_bugs" = "Num. of Pre-release Build Bugs",
  "num_pre_compatibility_bugs" = "Num. of Pre-release Compatibility Bugs",
  "num_pre_features" = "Num. of Pre-release Feature Bugs",
  "num_pre_regression_bugs" = "Num. of Pre-release Regression Bugs",
  "num_pre_security_bugs" = "Num. of Pre-release Security Bugs",
  "num_pre_stability_crash_bugs" = "Num. of Pre-release Stability Bugs",
  "num_pre_tests_fails_bugs" = "Num. of Pre-release Test Fail Bugs"
)
plot.source <- data.frame()
for(index in 1:length(COLUMN.LABELS)){
  cat(COLUMN.LABELS[[index]], "\n")
  plot.source <- rbind(
    plot.source,
    data.frame(
      "label" = COLUMN.LABELS[[index]],
      "value" = dataset[[names(COLUMN.LABELS)[index]]],
      "release" = factor(dataset$release, levels = unique(dataset$release)),
      "becomes_vulnerable" = dataset$becomes_vulnerable
    )
  )
}

### Export Resolution: 380 x 820
ggplot(plot.source, aes(x = becomes_vulnerable, y = value)) +
  geom_boxplot(
    aes(fill = factor(becomes_vulnerable, levels = c(TRUE, FALSE)))
  ) +
  scale_x_discrete(
    breaks = c(TRUE, FALSE), labels = c("TRUE" = "Yes", "FALSE" = "No")
  ) +
  scale_y_log10() +
  scale_fill_manual(
    values=c("#bfbfbf", "#ffffff"), name="Vulnerable",
    labels=c("TRUE" = "Yes", "FALSE" = "No")
  ) +
  facet_wrap(~ label, ncol = 1, scales = "free_y") +
  labs(
    title = "Bug Category Metrics", x = NULL, y = "Metric Value (Log Scale)"
  ) +
  plot.theme +
  theme(axis.text.x = element_blank())

##########################################
## Experience Metrics
##########################################

### Prepare Plotting Data Set
COLUMN.LABELS <- list(
  "avg_build_experienced_participants" =
    "% of Build Experienced Reviewers",
  "avg_compatibility_experienced_participants" =
    "% of Compatibility Experienced Reviewers",
  "avg_security_experienced_participants" =
    "% of Security Experienced Reviewers",
  "avg_bug_security_experienced_participants" =
    "% of Security Bug Experienced Reviewers",
  "avg_stability_experienced_participants" =
    "% of Stability Experienced Reviewers",
  "avg_test_fail_experienced_participants" =
    "% of Test Failure Experienced Reviewers"
)
plot.source <- data.frame()
for(index in 1:length(COLUMN.LABELS)){
  cat(COLUMN.LABELS[[index]], "\n")
  plot.source <- rbind(
    plot.source,
    data.frame(
      "label" = COLUMN.LABELS[[index]],
      "value" = dataset[[names(COLUMN.LABELS)[index]]],
      "release" = factor(dataset$release, levels = unique(dataset$release)),
      "becomes_vulnerable" = dataset$becomes_vulnerable
    )
  )
}

### Export Resolution: 380 x 820
ggplot(plot.source, aes(x = becomes_vulnerable, y = value)) +
  geom_boxplot(
    aes(fill = factor(becomes_vulnerable, levels = c(TRUE, FALSE)))
  ) +
  scale_x_discrete(
    breaks = c(TRUE, FALSE), labels = c("TRUE" = "Yes", "FALSE" = "No")
  ) +
  scale_y_continuous(labels = scales::percent) +
  scale_fill_manual(
    values=c("#bfbfbf", "#ffffff"), name="Vulnerable",
    labels=c("TRUE" = "Yes", "FALSE" = "No")
  ) +
  facet_wrap(~ label, ncol = 1, scales = "free_y") +
  labs(title = "Review Experience Metrics", x = NULL, y = "Metric Value") +
  plot.theme +
  theme(axis.text.x = element_blank())

###################################################################################
## Lift Curves
###################################################################################

#### Query Data
query <- "
  SELECT release, becomes_vulnerable
  FROM release_filepaths
  ORDER BY CAST(release AS NUMERIC) ASC, num_pre_bugs DESC
"
db.connection <- get.db.connection(db.settings)
dataset <- db.get.data(db.connection, query)
db.disconnect(db.connection)

### Prepare Plotting Data Set
plot.source <- data.frame()
for(release in unique(dataset$release)){
  cat("Release", release, "\n")
  release.dataset <- dataset[dataset$release == release,]

  file.count <- nrow(release.dataset)
  vuln.count <- nrow(
    release.dataset[release.dataset$becomes_vulnerable == TRUE,]
  )

  file.percent <- numeric(length = nrow(release.dataset))
  vuln.percent <- numeric(length = nrow(release.dataset))

  vuln.found <- 0
  for(index in 1:nrow(release.dataset)){
    if(release.dataset[index,]$becomes_vulnerable == TRUE){
      vuln.found <- vuln.found + 1
    }
    vuln.percent[index] <- vuln.found / vuln.count
    file.percent[index] <- index / file.count
  }

  plot.source <- rbind(
    plot.source,
    data.frame(
      "release" = release,
      "label" = paste("Release", release),
      "vuln.percent" = vuln.percent,
      "file.percent" = file.percent
    )
  )
}

# Export Resolution: 
ggplot(plot.source, aes(x = file.percent, y = vuln.percent)) +
  geom_line(size = 1) +
  facet_wrap(~ label, ncol = 1, scales = "free") +
  scale_x_continuous(labels = scales::percent, breaks = seq(0, 1.0, by = 0.1)) +
  scale_y_continuous(labels = scales::percent) +
  labs(main = "Lift Curves", x = "% Files", y = "% Vulnerable Files") +
  plot.theme