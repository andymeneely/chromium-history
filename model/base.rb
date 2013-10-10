require 'rubygems'
require 'yaml'
require 'active_record'

DB_YML_FILE = File.expand_path("database.yml")

dbconfig = YAML::load(File.open(DB_YML_FILE))
ActiveRecord::Base.establish_connection(dbconfig)


