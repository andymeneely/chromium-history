require 'rinruby'

class HypothesisTests

  def initialize
    R.echo false, false
  end

  def run
    puts "=== Hypothesis Test Results ==="
    connect_to_db
    mean_reviewers
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

  def mean_reviewers
    R.eval <<-EOR
      data <- dbReadTable(con, "release_filepaths")
      mean_reviewers <- mean(data$num_reviewers)
    EOR
    puts "Mean number of reviewers: #{R.mean_reviewers}"
  end
end
