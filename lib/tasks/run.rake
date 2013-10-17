# Our custom Rakefile tasks for loading the data
require_relative '../chromium_history/loaders/code_review_loader.rb'

task :run => [:environment, "db:reset", "run:load", "run:optimize", "run:verify", "run:analyze"] do
  puts "Run task completed"
end

namespace :run do
  desc "Delete data from all tables."
  task :clean => :environment do 
    Rails.application.eager_load! 
    ActiveRecord::Base.subclasses.each { |model| model.delete_all }
    puts "Tables cleaned."
  end

  desc "Load data into tables"
  task :load => :environment do |t, args|
    CodeReviewLoader.load
  end
  
  desc "Alias for run:clean then run:load"
  task :clean_load => ["run:clean", "run:load"]
  
  desc "Optimize the tables once data is loaded"
  task :optimize => :environment do
    # TODO: Read in some SQL and execute to pack our indexes
  end
  
  desc "Run our data verification tests"
  task :verify => :environment do
    # TODO: Delegate this off to a series of unit-test-like checks on our data.
  end
  
  desc "Analyze the data for metrics & questions"
  task :analyze => :environment do
    # TODO: Delegate this out to a list of classes that will assemble metrics and ask questions
  end
  
end