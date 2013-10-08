require 'rubygems'
require 'yaml'
require 'active_record'

dbconfig = YAML::load(File.open('../database.yml'))
puts dbconfig
ActiveRecord::Base.establish_connection(dbconfig)

