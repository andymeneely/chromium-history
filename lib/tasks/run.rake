# Our custom Rakefile tasks for loading the data
require_relative '../chromium_history/loaders/code_review_loader.rb'

task :run => [:environment, "db:reset", "run:load", "run:optimize", "run:verify", "run:analyze"] do
  puts "Run task completed"
end

namespace :run do

  desc "Delete data from all tables."
  task :clean => [:environment] do
    # Iterate over our models
    Dir[Rails.root.join('app/models/*.rb').to_s].each do |filename|
      klass = File.basename(filename, '.rb').camelize.constantize
      next unless klass.ancestors.include?(ActiveRecord::Base)
      klass.delete_all
    end
    puts "Tables cleaned."
  end

  desc "Load data into tables"
  task :load => :environment do
    Benchmark.bm(16) do |x|
      x.report("Loading code reviews: ") {CodeReviewLoader.new.load}
    end
  end
  
  desc "Alias for run:clean then run:load"
  task :clean_load => ["run:clean", "run:load"]
  
  desc "Optimize the tables once data is loaded"
  task :optimize => [:environment] do
    # Iterate over our models
    # TODO Refactor this out with rake run:clean so we're not repetitive
    Dir[Rails.root.join('app/models/*.rb').to_s].each do |filename|
      klass = File.basename(filename, '.rb').camelize.constantize
      next unless klass.ancestors.include?(ActiveRecord::Base)
      klass.send(:on_optimize)
    end
  end
  
  desc "Run our data verification tests"
  task :verify => :environment do
    # TODO: Delegate this off to a series of unit-test-like checks on our data.
  end
  
  desc "Analyze the data for metrics & questions"
  task :analyze => :environment do
    # TODO: Delegate this out to a list of classes that will assemble metrics and ask questions
  end
  
  desc "Which environment are we in?"
  task :which_env => :environment do
    puts Rails.env
  end
  
end