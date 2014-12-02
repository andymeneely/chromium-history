require 'csv'

class FirstOwnershipLoader

  def load
    datadir = File.expand_path(Rails.configuration.datadir)
    tmp = Rails.configuration.tmpdir
    ownership = CSV.open("#{tmp}/first-ownership.csv", 'w+')

    CSV.foreach("#{datadir}/first_ownership/first-owners.csv") do |line| 
	  em = Developer.search_or_add(line[0]) 
	  next if (em[0].nil?)
	  dev_id = Developer.where(email: em[0]).limit(1).pluck(:id)[0]
	  owner_email = em[0]
	  commitHash = line[2]
	  filepath = line[1]
	  ownership << [owner_email, dev_id, filepath, commitHash]
    end
    ownership.fsync
	ActiveRecord::Base.connection.execute("COPY first_ownerships FROM '#{tmp}/first-ownership.csv' DELIMITER ',' CSV")
  end
end