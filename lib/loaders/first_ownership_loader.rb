require 'csv'

class FirstOwnershipLoader

  def load
    datadir = File.expand_path(Rails.configuration.datadir)

    CSV.foreach("#{datadir}/first_ownership/first-owners.csv") do |line|
      dev = Developer.search_or_add(line[0]) 
      if dev.nil? 
        unless line[0].eql? "ALL" # Skip ALL for now
          $stderr.puts "First ownership email is invalid: #{line[0]}"
        end
      else
        ReleaseOwner.where(dev_id: dev.id, directory: line[1]).update_all(first_ownership_sha: line[2], first_ownership_date: line[3])
      end
    end
  end
end
