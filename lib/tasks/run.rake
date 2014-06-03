# Our custom Rakefile tasks for loading the data
require 'loaders/code_review_parser'
require 'loaders/code_review_loader'
require 'loaders/cve_loader'
require 'loaders/git_log_loader'
require 'consolidators/filepath_consolidator'
require 'consolidators/developer_consolidator'
require 'verify/verify_runner'
require 'stats'

task :run => [:environment, "run:env", "run:prod_check", "db:reset", "run:slurp", "run:verify", "run:analyze"] do
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
      x.report("Optimizing commits et al.") do 
        [Commit,CommitFilepath,Cvenum]
      end
      x.report("Consolidating participants") {DeveloperConsolidator.new.consolidate_participants}
      x.report("Consolidating contributors") {DeveloperConsolidator.new.consolidate_contributors}
      x.report("Consolidating filepaths") {FilepathConsolidator.new.consolidate}
      
      x.report("Optimizing contributors"){ Contributor.on_optimize}
      x.report("Optimizing participants"){ Participant.on_optimize}
      x.report("Optimizing filepath"){ Filepath.on_optimize}
      x.report("Deleting duplicate reviewers") {DeveloperConsolidator.new.consolidate_reviewers}
    end
  end

  desc "Run our data verification tests"
  task :verify => :env do
    VerifyRunner.run_all
  end

  desc "Analyze the data for metrics & questions"
  task :analyze => :environment do
    # TODO: Delegate this out to a list of classes that will assemble metrics and ask questions
  end

  desc "Show some stats on the data set"
  task :stats => :env do
    stats_start = Time.now
    Stats.new.run_all
    time_taken = Time.now - stats_start
    puts "Rake run:stats took #{time_taken.round(1)}s, which is #{(time_taken/60).round(2)} minutes."
  end

end
