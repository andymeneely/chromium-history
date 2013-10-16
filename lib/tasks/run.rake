require 'oj'

namespace :run do
  desc "Load data into tables"
  task :load => :environment do
    obj = Oj.load_file('test/data/9141024.json')
    CodeReview.create(description: obj['description'], subject: obj['subject'])
    puts "Done."
  end
end