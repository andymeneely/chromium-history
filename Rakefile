require "bundler/gem_tasks"
require "active_record"

Dir[File.dirname(__FILE__) + '/model/*.rb'].each{|file| require file} #require Models and Base

# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

ChromiumHistory::Application.load_tasks

# TODO: Move these tasks below into lib/tasks, as described above

#run rake -T to see all available rake commands and their descriptions
namespace :db do 

	desc "Clean all the tables in Database"
	task :clean do
		clean_db
	end

	desc "Load the new data in the data files located in the data folder"
	task :load do
		load_owners
	end

	desc "Analyze the new data entered into the database"
	task :analyze do
	end
end

# Method cleans out all the tables represented in our Model
def clean_db
	ActiveRecord::Base.connection.tables.each do |table|
	  next if table.match(/\Aschema_migrations\Z/) #Do Not Touch
	  model = table.singularize.camelize.constantize 
	  puts "BEFORE: #{model.name} has #{model.count} records"
	  model.delete_all    
	  puts "AFTER: #{model.name} has #{model.count} records\n\nd"
	end
end

# Load all the Owners from the "allTheOwners.txt" file
def load_owners
	File.open("data/OWNERS files results/allTheOwners.txt").each_line do |line|
		Owner.create(chromium_email: line.strip)
	end
end


