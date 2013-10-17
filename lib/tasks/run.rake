require 'oj'

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
    obj = Oj.load_file("#{Rails.configuration.datadir}/9141024.json")
    # TODO: Refactor out to a CodeReview parser to a separate class
    c = CodeReview.create(description: obj['description'], subject: obj['subject'], created: obj['created'], modified: obj['modified'], issue: obj['issue'])
    obj['patchsets'].each do |id| 
      pobj = Oj.load_file("test/data/9141024/#{id}.json")
      p = PatchSet.create(message: pobj['message'], num_comments: pobj['num_comments'], patchset: pobj['patchset'], created: obj['created'], modified: obj['modified'])
      c.patch_sets << p
    end
    puts "Loading done."
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