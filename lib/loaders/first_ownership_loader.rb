require 'csv'

class FirstOwnershipLoader

  def load
    datadir = File.expand_path(Rails.configuration.datadir)
	
    CSV.foreach("#{datadir}/first_ownership/first-owners.csv") do |line|
	  em = Developer.search_or_add(line[0]) 
	  unless(em[0].nil?)
	    id = Developer.where(email: em[0]).limit(1).pluck(:id)[0]
	    ReleaseOwner.where(dev_id: id , owner_email: em[0], directory: line[1]).update_all(first_ownership_sha: line[2], first_ownership_date: line[3])
	  else
	    abort ("Failed to clear email: #{line[0]}")
	  end
    end
  end
end