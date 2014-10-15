require 'csv'

class OwnersParser

  def parse
    datadir = File.expand_path(Rails.configuration.datadir)
    tmp = Rails.configuration.tmpdir
    owners = CSV.open("#{tmp}/parsed_owners.csv", 'w+')
    CSV.foreach("#{datadir}/owners/owners.csv") do |line| 
      if (Release.exists?(:name => line[0]) and Filepath.exists?(:filepath => line[1]))
        release = line[0]
        filepath = line[1]
        owner_email = line[2]
        owners << [release, filepath, owner_email]
      end
    end
    owners.fsync
  end
end
