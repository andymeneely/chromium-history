# Our custom Rakefile tasks for loading the data
require 'loaders/code_review_parser'
require 'loaders/code_review_loader'
require 'loaders/cve_loader'
require 'loaders/git_log_loader'
require 'loaders/release_filepath_loader'
require 'loaders/sloc_loader'
require 'loaders/sheriff_rotation_loader'
require 'consolidators/filepath_consolidator'
require 'consolidators/developer_consolidator'
require 'verify/verify_runner'
require 'analysis/release_analysis'
require 'analysis/participant_analysis'
require 'analysis/hypothesis_tests'
require 'analysis/code_review_analysis.rb'
require 'analysis/data_visualization'
require 'analysis/visualization_queries'
require 'stats'

# CodeReviewParser.new.parse: Parses JSON files in the codereviews dircetory for the enviornment we're working in.
    	# Loads the json files into an object(a hash). Then pushes data from the created object
    	# to the code review's csvfile, saves developers in a csv, and syncs the object and the file.
# CodeReviewLoader.new.copy_parsed_tables: Copies the data from it's respective file (parsed from JSON) to a table.
	# Copies the data into a table from files in the datadir we're working in. 
        # It does this in CSV mode with a comma as a delimeter.
# |c| c.on_optimize: Used on code reviews, commits, releases, contributer, participant, and filepath  models. 
	# Optimizes respective data for named classes that deal with what's in the datas table
	# Optimizes by adding indexes to each column 
# CodeReviewLoader.new.add_primary_keys: creates a serial id column and makes the primary key the id field
        # Adds a serial id column and make a primary key constraint to a table (noting 
        # that a table can only ever have one primary key). It also creates an index on code_reviews.
# CveLoader.new.load_cve: Loads csv files of vulnerabilites and adds issues to unique cve
	# Gets the resultFile from the config datatdir if in the dev env, otherwise builds the results set.
	# Each row from the file is checked to see if it is unique and added to the table and link if it is.
	# Data from these files into a table from the datadir we're working in. 
	# Extra issues that are not loaded into our database are deleted.
# GitLogLoader.new.load: parses git log commit files and extracts the relevant information from them
	# A prepared INSERT INTO statement is made for the commit and the file(uses placeholders for values $1, $2, etc). 
	# Commits are opened from a file in the environment we're working in, processed, structured in a hash and saved to the database
# ReleaseFilepathLoader.new.load: The release and filepath are transfered to a new csv by padding with however many empty colums we have
	# Files are transfered and padded and then copied from the release filepaths file in the dir we're working in
# FilepathConsolidator.new.consolidate: Given all locations of filepaths that we know of, make one Filepath table
# DeveloperConsolidator.new.consolidate_reviewers: deletes duplicate reviewers
	# Delete rows that are duplicates over a set of columns, keeping only the one with the lowest ID. 

task :run => [:environment, "run:env", "run:prod_check", "db:reset", "run:slurp", "run:analyze", "run:verify"] do
  puts "Run task completed. Current time is #{Time.now}"
end

namespace :run do
  
  desc "Show current environment information"
  task :env => :environment do
    puts "\tEnv.:     #{Rails.env}"
    puts "\tData:     #{Rails.configuration.datadir}"
    puts "\tDatabase: #{Rails.configuration.database_configuration[Rails.env]["database"]}"
    puts "\tStart: #{Time.now}"
  end
  
  desc "Only proceed if we are SURE, or not in production"
  task :prod_check => :env do
    if 'production'.eql?(Rails.env) && !ENV['RAILS_BLAST_PRODUCTION'].eql?('YesPlease')
      $stderr.puts "WOAH! Hold on there. Are you trying to blow away our production database. Better use the proper environment variable (see our source)"
      raise "Reset with production flag not set"
    end
  end
  
  desc "Parse, load, optimize, and consolidate"
  task :slurp => [:environment,"db:reset"] do
    Benchmark.bm(30) do |x|
      x.report("Parsing JSON Code Reviews") {CodeReviewParser.new.parse}
      x.report("Loading Code Review CSVs") {CodeReviewLoader.new.copy_parsed_tables}
      x.report("Optimizing Code Reviews et al.") do
        [CodeReview,PatchSet,PatchSetFile,Comment,Developer,Message,Reviewer].each {|c| c.on_optimize}
      end
      x.report("Keying Developers") { CodeReviewLoader.new.add_primary_keys }
      x.report("Loading CVEs ") {CveLoader.new.load_cve}
      x.report("Loading git log") {GitLogLoader.new.load}
      x.report("Loading sheriffs") {SheriffRotationLoader.new.parse_and_load}
      x.report("Optimizing commits, cve,et al.") do 
        [Commit,CommitFilepath,Cvenum].each {|c| c.on_optimize}
      end
      x.report("Optimizing sheriffs") { SheriffRotation.on_optimize}
      x.report("Loading release tree") {ReleaseFilepathLoader.new.load}
      x.report("Optimizing releases et al.") do 
        [Release,ReleaseFilepath].each{|c| c.on_optimize}
      end
      x.report("Consolidating filepaths") {FilepathConsolidator.new.consolidate}
      x.report("Loading sloc") {SlocLoader.new.load}
      x.report("Optimizing contributors"){ Contributor.on_optimize}
      x.report("Optimizing participants"){ Participant.on_optimize}
      x.report("Optimizing filepath"){ Filepath.on_optimize}
      x.report("Deleting duplicate reviewers") {DeveloperConsolidator.new.consolidate_reviewers}
      x.report("Running PSQL ANALYZE"){ ActiveRecord::Base.connection.execute "ANALYZE" }
    end
  end
  
  desc "Analyze the data for metrics"
  task :analyze => :environment do
    Benchmark.bm(30) do |x|
      x.report("Populating reviews_with_owner"){ParticipantAnalysis.new.populate_reviews_with_owner}
      x.report("Populating security_experienced"){ParticipantAnalysis.new.populate_security_experienced}
      x.report("Populating total_reviews_with_owner"){CodeReviewAnalysis.new.populate_total_reviews_with_owner}
      x.report("Populating owner_familiarity_gap"){CodeReviewAnalysis.new.populate_owner_familiarity_gap}
      x.report("Populating sheriff_hours") {ParticipantAnalysis.new.populate_sheriff_hours}
      x.report("Populating total_sheriff_hours"){CodeReviewAnalysis.new.populate_total_sheriff_hours}
      x.report("Populating release metrics") {ReleaseAnalysis.new.populate}
    end
  end

  desc "Run our data verification tests"
  task :verify => :env do
    VerifyRunner.run_all
  end

  namespace :verify do

    desc "Run our data verification tests with coverage test"
    task :coverage => :env do
      require 'simplecov'
      SimpleCov.start
      Rake::Task["run:verify"].invoke
    end

  end#namspace :verify

  desc "Show some stats on the data set"
  task :stats => :env do
    stats_start = Time.now
    Stats.new.run_all
    time_taken = Time.now - stats_start
    puts "Rake run:stats took #{time_taken.round(1)}s, which is #{(time_taken/60).round(2)} minutes."
  end

  desc "Run final hypothesis tests"
  task :results => :env do
    HypothesisTests.new.run
  end

  desc "run r data visualization"
  task :visualize => :env do
   VisualizationQueries.new.run_queries
   puts "Visualization queries finished at #{Time.now}"
   DataVisualization.new.run
   puts "Graphs created at #{Time.now}"
  end
end
