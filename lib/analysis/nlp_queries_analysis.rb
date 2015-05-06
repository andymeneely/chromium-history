require 'rinruby'

class NlpQueriesAnalysis

  def initialize
    R.echo false, false
  end

  def run
    #create the technical word use in msgs and reviews tables
    create_freq_tables
	
    connect_db

    #get the technical words and use weight in msgs and reviews per associated labels
    technical_messages_vs_buglabels
    technical_reviews_vs_buglabels
	
    #from the weighted word-use tables, get only the top-ranked 20 words in use for each label_id
    create_top_tech_words_tables
    close_db
  end
  
  def connect_db
    conf = Rails.configuration.database_configuration[Rails.env]
    #To install these packages locally, run R on the command line
    # and then run
    # >>> install.packages("DBI")
    # >>> install.packages("RPostgreSQL")
    # >>> install.packages("ROCR")
    # >>> install.packages("bestglm")
    # >>> install.packages("lsr")
    # >>> install.packages("reshape2")
    # >>> install.packages("NLP")
    # >>> install.packages("tm")
    #
    # If tm doesn't not install due to issues with R version, download old package archive
    # and install it directly from a source directory:
    # archives_url: http://cran.r-project.org/src/contrib/Archive/tm/ , Now using: tm_0.5-9.1.tar.gz
    #
    # In teminal type: wget "replace with a source url from archives". Downloads archive to current dir
    # Open R and run:
    # >>> install.packages(path_to_downloaded_src_archive, repos=NULL, type="source")
    R.echo false,false
    R.eval <<-EOR
      library(DBI)
      library(RPostgreSQL)
      library(reshape2)
      library(slam)
      library(NLP)
      library(tm)
      drv <- dbDriver("PostgreSQL")
      con <- dbConnect(drv, 
                       user="#{conf['username']}", 
                       password="#{conf['password']}", 
                       dbname="#{conf['database']}")
    EOR
  end

  def close_db
    R.echo false,false
    R.eval <<-EOR
      dbDisconnect(con)
      dbUnloadDriver(drv)
    EOR
  end
  
  def technical_messages_vs_buglabels
    R.echo false,false
    R.eval <<-EOR
      #get the frequency data from tables in the db
      msgfreqdata <- dbReadTable(con,'labtechmsgfreqs')
	
      #convert the freqs data frames to matrices
      msgfreqmatrix <- acast(msgfreqdata,label_id~word_id,value.var='freq')
    
      #remove na values, replace them with 0
      msgfreqmatrix[is.na(msgfreqmatrix)] <- 0
	
      #convert the frequency matrices to DocumentTermMatrix, Labels as document, and tech words as the terms, using tfidf as word weight
      msgdtm <- as.DocumentTermMatrix(msgfreqmatrix,weightTfIdf)
	
      #convert to matrix with term weights
      msgdtm2 <- as.matrix(msgdtm)

      #remove unused words
      msgdtm2[msgdtm2 == 0] <- NA

      #convert the matrices into data frames to save
      label_msg_top_words <- melt(msgdtm2,varnames = c('label_id','word_id'),na.rm=TRUE,value.name='weightTfIdf')

      #save matrices as tables
      names(label_msg_top_words) <- tolower(names(label_msg_top_words))
      dbWriteTable(con,'label_msg_top_words',label_msg_top_words,row.names=FALSE,overwrite=TRUE)
    EOR
  end
  
  def technical_reviews_vs_buglabels
    R.echo false,false
    R.eval <<-EOR
      #get the frequency data from tables in the db
      revfreqdata <- dbReadTable(con,'labtechrevfreqs')
	
      #convert the freqs data frames to matrices
      revfreqmatrix <- acast(revfreqdata,label_id~word_id,value.var='freq')
	
      #remove na values, replace them with 0
      revfreqmatrix[is.na(revfreqmatrix)] <- 0
	
      #convert the frequency matrices to DocumentTermMatrix, Labels as document, and tech words as the terms, using tfidf as word weight
      revdtm <- as.DocumentTermMatrix(revfreqmatrix,weightTfIdf)
	
      #convert to matrix with term weights
      revdtm2 <- as.matrix(revdtm)

      #remove unused words
      revdtm2[revdtm2 == 0] <- NA

      #convert the matrices into data frames to save
      label_rev_top_words <- melt(revdtm2,varnames = c('label_id','word_id'),na.rm=TRUE,value.name='weightTfIdf')

      #save matrices as tables
      names(label_rev_top_words) <- tolower(names(label_rev_top_words))
      dbWriteTable(con,'label_rev_top_words',label_rev_top_words,row.names=FALSE,overwrite=TRUE)
    EOR
  end
  
  def create_freq_tables
  
    #create a table with counts for technical messages by label & technical word
    drop_label_tech_msgs_table = 'DROP TABLE IF EXISTS label_tech_msgs'
    create_label_tech_msgs_table = <<-EOSQL
      CREATE TABLE label_tech_msgs AS (
        SELECT l.label AS label, tw.word AS word, count(*) AS freq
        FROM labels l INNER JOIN bug_labels bl ON  bl.label_id = l.label_id 
	              INNER JOIN bugs b ON b.bug_id = bl.bug_id 
                      INNER JOIN commit_bugs cb ON cb.bug_id = b.bug_id 
                      INNER JOIN commits c ON c.commit_hash = cb.commit_hash 
		      INNER JOIN code_reviews cr ON cr.commit_hash = c.commit_hash
                      INNER JOIN messages m ON m.code_review_id = cr.issue 
                      INNER JOIN messages_technical_words mtw ON mtw.message_id = m.id 
                      INNER JOIN technical_words tw ON tw.id = mtw.technical_word_id 
        GROUP BY l.label, tw.word
      )
    EOSQL

    #create a table with counts for technical reviews by label & technical word
    drop_label_tech_reviews_table = 'DROP TABLE IF EXISTS label_tech_reviews'
    create_label_tech_reviews_table = <<-EOSQL
      CREATE TABLE label_tech_reviews AS (
        SELECT l.label AS label, tw.word AS word, count(*) AS freq 
        FROM labels l INNER JOIN bug_labels bl ON  bl.label_id = l.label_id
                      INNER JOIN bugs b ON b.bug_id = bl.bug_id 
                      INNER JOIN commit_bugs cb ON cb.bug_id = b.bug_id 
                      INNER JOIN commits c ON c.commit_hash = cb.commit_hash 
                      INNER JOIN code_reviews cr ON cr.commit_hash = c.commit_hash 
                      INNER JOIN code_reviews_technical_words cr_tw ON cr_tw.code_review_id = cr.issue 
                      INNER JOIN technical_words tw ON tw.id = cr_tw.technical_word_id 
        GROUP BY l.label, tw.word
      )
    EOSQL

    #create a table with frequencies for label/tech word use in messages
    drop_labtechmsgfreqs = 'DROP TABLE IF EXISTS labtechmsgfreqs'
    create_labtechmsgfreqs = <<-EOSQL
      CREATE TABLE labtechmsgfreqs AS (
	    SELECT l.label_id AS label_id, tw.id AS word_id, ltm.freq AS freq FROM label_tech_msgs ltm INNER JOIN labels l ON l.label = ltm.label
		                                                                                       INNER JOIN technical_words tw ON tw.word = ltm.word
      )
    EOSQL
    
    #create a table with frequencies for label/tech word use in reviews
    drop_labtechrevfreqs = 'DROP TABLE IF EXISTS labtechrevfreqs'
    create_labtechrevfreqs = <<-EOSQL
      CREATE TABLE labtechrevfreqs AS (
	    SELECT l.label_id AS label_id, tw.id AS word_id, ltm.freq AS freq FROM label_tech_reviews ltm INNER JOIN labels l ON l.label = ltm.label
		                                                                                          INNER JOIN technical_words tw ON tw.word = ltm.word
      )
    EOSQL

    Benchmark.bm(40) do |x|
      x.report("Executing drop label_techmsgs cnts") {ActiveRecord::Base.connection.execute drop_label_tech_msgs_table}
      x.report("Executing create label_techmsgs cnts") {ActiveRecord::Base.connection.execute create_label_tech_msgs_table}
      
      x.report("Executing drop label_techrevs cnts") {ActiveRecord::Base.connection.execute drop_label_tech_reviews_table}
      x.report("Executing create label_techrevs cnts") {ActiveRecord::Base.connection.execute create_label_tech_reviews_table}

      x.report("Executing drop labtechmsgfreqs table") {ActiveRecord::Base.connection.execute drop_labtechmsgfreqs}
      x.report("Executing create labtechmsgfreqs table") {ActiveRecord::Base.connection.execute create_labtechmsgfreqs}

      x.report("Executing drop labtechrevfreqs table") {ActiveRecord::Base.connection.execute drop_labtechrevfreqs}
      x.report("Executing create labtechrevfreqs table") {ActiveRecord::Base.connection.execute create_labtechrevfreqs}
    end
  end
  
  def create_top_tech_words_tables
    drop_top_msg_words = 'DROP TABLE IF EXISTS top_msg_words'										 
    create_top_msg_words = 'CREATE TABLE top_msg_words AS (SELECT * FROM (SELECT label_id, word_id, weighttfidf, rank() OVER (PARTITION BY label_id ORDER BY weighttfidf DESC) AS rank FROM label_msg_top_words) t WHERE rank < 21)'
	
    drop_top_rev_words = 'DROP TABLE IF EXISTS top_rev_words'
    create_top_rev_words = 'CREATE TABLE top_rev_words AS (SELECT * FROM (SELECT label_id, word_id, weighttfidf, rank() OVER (PARTITION BY label_id ORDER BY weighttfidf DESC) AS rank FROM label_rev_top_words) t WHERE rank < 21)'
	
    ActiveRecord::Base.connection.execute drop_top_msg_words
    ActiveRecord::Base.connection.execute create_top_msg_words

    ActiveRecord::Base.connection.execute drop_top_rev_words
    ActiveRecord::Base.connection.execute create_top_rev_words
  end
end
