require 'csv'
require	"pathname"

class FirstOwnershipLoader

  def load
    datadir = File.expand_path(Rails.configuration.datadir)
    tmp = Rails.configuration.tmpdir
    ownership = CSV.open("#{tmp}/first-ownership.csv", 'w+')

    CSV.foreach("#{datadir}/first_ownership/first-owners.csv") do |line|
	  em = Developer.search_or_add(line[0]) 
	  unless(em[0].nil?)
	    if(ReleaseOwner.exists?(:owner_email => em[0], :directory => line[1]))
	      dev_id = Developer.where(email: em[0]).limit(1).pluck(:id)[0]
	      owner_email = em[0]
	      commitHash = line[2]
	      date = line[3]
	      directory = line[1]
	      ownership << [owner_email, dev_id, directory, commitHash, date]
		end
	  else
	    abort ("Failed to clear email: #{line[0]}")
	  end
    end
    ownership.fsync
	ActiveRecord::Base.connection.execute("COPY first_ownerships FROM '#{tmp}/first-ownership.csv' DELIMITER ',' CSV")
  end
  
  def related?(parent, subdirs)
    if parent.eql?("./")
	  return true
	end
    subdirs.each do |subdir|
	  Pathname.new(subdir).ascend do |s|
	  s = "#{s}/"
        if(parent.eql? s)
          return true
	    end
	  end
	end
	return false
  end
end