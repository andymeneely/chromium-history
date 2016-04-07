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