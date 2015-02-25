# Our custom Rakefile tasks for loading the data
require 'loaders/bug_parser.rb'
require 'loaders/code_review_parser'
require 'loaders/code_review_loader'
require 'loaders/cve_loader'
require 'loaders/git_log_loader'
require 'loaders/release_filepath_loader'
require 'loaders/sloc_loader'
require 'loaders/sheriff_rotation_loader'
require 'loaders/first_ownership_loader.rb'
require 'loaders/owners_loader.rb'
require 'consolidators/filepath_consolidator'
require 'consolidators/developer_consolidator'
require 'verify/verify_runner'
require 'analysis/release_analysis'
require 'analysis/participant_analysis'
require 'analysis/hypothesis_tests'
require 'analysis/code_review_analysis'
require 'analysis/data_visualization'
require 'analysis/visualization_queries'
require 'analysis/ascii_histograms'
require 'stats'
require 'nlp/corpus'
require 'utils/psql_util'
require 'loaders/vocab_loader'
require 'oj'

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
    puts "\tTemp:     #{Rails.configuration.tmpdir}"
    puts "\tDatabase: #{Rails.configuration.database_configuration[Rails.env]["database"]}"
    puts "\tStart:    #{Time.now}"
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
    Benchmark.bm(40) do |x|
      x.report("Parsing JSON Code Reviews") {CodeReviewParser.new.parse}
      x.report("Loading Code Review CSVs") {CodeReviewLoader.new.copy_parsed_tables}
      x.report("Optimizing Code Reviews et al.") do
        [CodeReview,PatchSet,PatchSetFile,Comment,Developer,Message,Reviewer].each {|c| c.optimize}
      end
      x.report("Keying Developers") { CodeReviewLoader.new.add_primary_keys }
      x.report("Loading CVEs ") {CveLoader.new.load_cve}
      x.report("Loading git log") {GitLogLoader.new.load}
      x.report("Loading sheriffs") {SheriffRotationLoader.new.parse_and_load}
      x.report("Parsing data from JSON Bugs"){BugParser.new.parse_and_load_json}
      x.report("Optimizing bug entries,comments") do
        [Bug,BugComment].each {|c| c.optimize}
      end
      x.report("Parsing data from Bug CSVs"){BugParser.new.parse_and_load_csv}
      x.report("Optimizing block,labels,et al.") do
        [Block,Label,BugLabel].each {|c| c.optimize}
      end
      x.report("Optimizing commits, cve,et al.") do 
        [Commit,CommitFilepath,CommitBug,Cvenum].each {|c| c.optimize}
      end
      x.report("Optimizing sheriffs") { SheriffRotation.optimize}
      x.report("Loading release tree") {ReleaseFilepathLoader.new.load}
      x.report("Optimizing releases et al.") do 
        [Release,ReleaseFilepath].each{|c| c.optimize}
      end
      x.report("Consolidating filepaths") {FilepathConsolidator.new.consolidate}
      x.report("Loading sloc") {SlocLoader.new.load}
      x.report("Optimizing participants"){ Participant.optimize}
      x.report("Optimizing filepath"){ Filepath.optimize}
      x.report("Deleting duplicate reviewers") {DeveloperConsolidator.new.consolidate_reviewers}
      x.report("Loading release OWNERS") {OwnersLoader.new.load}
      x.report("Optimizing OWNERS") {ReleaseOwner.optimize}
      x.report("Loading First Ownership"){FirstOwnershipLoader.new.load}
      x.report("Running PSQL ANALYZE"){ ActiveRecord::Base.connection.execute "ANALYZE" }
      vocab_loader = VocabLoader.new
      x.report('Generating technical vocab') {vocab_loader.load}
      x.report('Associating vocab words with messages'){vocab_loader.reassociate_messages}
      x.report("Running PSQL ANALYZE"){ ActiveRecord::Base.connection.execute "ANALYZE" }
    end
  end
  
  desc "Analyze the data for metrics"
  task :analyze => :environment do
    Benchmark.bm(40) do |x|
      x.report("Populating reviews_with_owner"){ParticipantAnalysis.new.populate_reviews_with_owner}
      x.report("Populating security_experienced"){CodeReviewAnalysis.new.populate_experience_cve}
      x.report("Populating dev experience dates"){CodeReviewAnalysis.new.populate_experience_labels}
      x.report("Populating participant bug experience"){ParticipantAnalysis.new.populate_bug_related_experience}
      x.report("Populating total_reviews_with_owner"){CodeReviewAnalysis.new.populate_total_reviews_with_owner}
      x.report("populating security_adjacencys"){ParticipantAnalysis.new.populate_security_adjacencys}
      x.report("Populating owner_familiarity_gap"){CodeReviewAnalysis.new.populate_owner_familiarity_gap}
      x.report("Populating sheriff_hours") {ParticipantAnalysis.new.populate_sheriff_hours}
      x.report("Populating total_sheriff_hours"){CodeReviewAnalysis.new.populate_total_sheriff_hours}
      x.report("Populating release metrics") {ReleaseAnalysis.new.populate}
      #puts "Here are a bunch of SQL Explains"
      #Filepath.print_sql_explains
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
    #VisualizationQueries.new.run_queries
    #DataVisualization.new.run
  end

  desc "run r data visualization"
  task :visualize => :env do
   VisualizationQueries.new.run_queries
   puts "Visualization queries finished at #{Time.now}"
   DataVisualization.new.run
   puts "Graphs created at #{Time.now}"

  end

  desc "Show some histograms"
  task :hist => :env do
   ASCIIHistograms.new.run
   puts "ASCII Histograms created at #{Time.now}"
  end

  namespace :nlp do
    desc "Building Technical Vocab"
    task :build_vocab => :env do
      Benchmark.bm(40) do |x|
        vocab_loader = VocabLoader.new
        x.report('Generating technical vocab') {vocab_loader.load}
        x.report('Associating vocab words with comments') {vocab_loader.reassociate_comments}
        x.report('Associating vocab words with messages'){vocab_loader.reassociate_messages}
      end
    end
	
	desc "Running interesting nlp queries"
    task :nlp_queries => :env do
	  x.report('Technical words associated with too many labels: ') do
	    puts
		puts "#{TechnicalWord.joins(messages: {code_review: {commit: {commit_bugs: {bug: :labels}}}}).group("technical_words.id").order("COUNT(labels.label) DESC").limit(50).select("technical_words.id",:word,"COUNT(labels.label)")}"
	  end
	  x.report(' Top word-bug label pairs: ') do
	    puts
		puts "#{TechnicalWord.joins(messages: {code_review: {commit: {commit_bugs: {bug: :labels}}}}).group("technical_words.id","labels.label").order("COUNT(*) DESC").limit(50).select(:word,"labels.label","COUNT(*)")}"
	  end
	  x.report('Top technical words in reviews for commits associated to bugs') do
	    puts
		puts "#{CodeReview.joins(messages: :technical_words).where(commit_hash: CommitBug.pluck('DISTINCT commit_hash')).group(:word).order('COUNT(code_reviews.issue) DESC').limit(50).select(:word,'COUNT(code_reviews.issue)')}"
	  end
	  x.report('Top technical words in reviews for commits NOT associated to bugs') do
	    puts
		puts "#{CodeReview.joins(messages: :technical_words).where.not(commit_hash: CommitBug.pluck('DISTINCT commit_hash')).group(:word).order('COUNT(code_reviews.issue) DESC').limit(50).select(:word,'COUNT(code_reviews.issue)')}"
	  end
	  x.report('Average technical words in reviews for commits with bug associations') do
	    puts
		puts "#{(CodeReview.joins(messages: :technical_words).where(commit_hash: CommitBug.pluck('DISTINCT commit_hash')).pluck(:word).count).to_f/(CodeReview.where(commit_hash: CommitBug.pluck('DISTINCT commit_hash')).count)}"
	  end
	  x.report('Average technical words in reviews for commits without bugs associated') do
	    puts
		puts "#{(CodeReview.joins(messages: :technical_words).where.not(commit_hash: CommitBug.pluck('DISTINCT commit_hash')).pluck(:word).count).to_f/(CodeReview.where.not(commit_hash: CommitBug.pluck('DISTINCT commit_hash')).count)}"
	  end
	  x.report('Check increase of word usage over time') do
	    range0 = DateTime.parse('Tue, 5 Jan 1999 05:15:42 UTC +00:00')..Release.where(name: '5.0').pluck(:date)[0]
		range1 = Release.where(name: '5.0').pluck(:date)[0]..Release.where(name: '11.0').pluck(:date)[0]
		range2 = Release.where(name: '11.0').pluck(:date)[0]..Release.where(name: '19.0').pluck(:date)[0]
		range3 = Release.where(name: '19.0').pluck(:date)[0]..Release.where(name: '27.0').pluck(:date)[0]
		range4 = Release.where(name: '27.0').pluck(:date)[0]..Release.where(name: '35.0').pluck(:date)[0]
		
	    ids = Participant.where(review_date: range0).pluck(:dev_id) + Reviewer.joins(:code_review).where(code_reviews: {created: range0}).pluck(:dev_id)
		
		old_words = Message.joins(:technical_words).where(date: range0, sender_id: ids).pluck('distinct word')
        old_usage = Message.joins(:technical_words).where(date: range0, sender_id: ids).group(:sender_id, :word).pluck(:sender_id, :word)
		
        usage1 = Message.joins(:technical_words).where(messages: {date: range1, sender_id: ids},technical_words: {word: old_words}).group(:sender_id, :word).pluck(:sender_id, :word)
		usage2 = Message.joins(:technical_words).where(messages: {date: range2, sender_id: ids},technical_words: {word: old_words}).group(:sender_id, :word).pluck(:sender_id, :word)
		usage3 = Message.joins(:technical_words).where(messages: {date: range3, sender_id: ids},technical_words: {word: old_words}).group(:sender_id, :word).pluck(:sender_id, :word)
		usage4 = Message.joins(:technical_words).where(messages: {date: range4, sender_id: ids},technical_words: {word: old_words}).group(:sender_id, :word).pluck(:sender_id, :word)
		
	    puts
		puts "New dev usage of words from 5.0 in 11.0: #{(usage1 - old_usage).count}"
		puts "New dev usage of words from 5.0 in 19.0: #{(usage2 - usage1 - old_usage).count}"
		puts "New dev usage of words from 5.0 in 27.0: #{(usage3 - usage1 - usage2 - old_usage).count}"
		puts "New dev usage of words from 5.0 in 35.0: #{(usage4 - usage1 - usage2 - usage3 - old_usage).count}"
	  end
    end
	
  end
end
