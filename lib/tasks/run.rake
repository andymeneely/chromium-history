require 'oj'

task :run => [:environment, "db:reset", "run:load", "run:optimize", "run:verify", "run:analyze"] do
  puts "Run task completed"
end

namespace :run do
  desc "Load data into tables"
  task :load => :environment do
    # TODO: Read from our test directory
    obj = Oj.load_file('test/data/9141024.json')
    # TODO: Refactor out to a CodeReview parser
    CodeReview.create(description: obj['description'], subject: obj['subject'])
    puts "Loading done."
  end
  
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