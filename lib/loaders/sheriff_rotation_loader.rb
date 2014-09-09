require 'csv'

class SheriffRotationLoader

  def parse_and_load
    
    #parse
    @sheriffs = CSV.open("/tmp/sheriffs.csv", 'w+')
    datadir = File.expand_path(Rails.configuration.datadir)
    
    sheriff_id = 0
    CSV.foreach("#{datadir}/sheriffs.csv") do |line| 
      email = Developer.search_or_add line[4]
      dev_id = Developer.where(email: email).pluck(:id).first.to_i
      start = line[1] ; duration =  line[3] ; title = line[0]
      
      @sheriffs << [sheriff_id, dev_id, start, duration, title]
      sheriff_id += 1
    end
    
    @sheriffs.fsync
    
    ActiveRecord::Base.connection.execute("COPY sheriff_rotations FROM '/tmp/sheriffs.csv' DELIMITER ',' CSV")
  end
end
