require 'rinruby'

module RinrubyUtil
  def connect_to_db(&block)
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
    yield
    R.eval <<-EOR
      dbDisconnect(con)
      dbUnloadDriver(drv)
    EOR
  end
end
