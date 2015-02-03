require 'csv'

class OwnersLoader

  def load
    datadir = File.expand_path(Rails.configuration.datadir)
    tmp = Rails.configuration.tmpdir
    owners = CSV.open("#{tmp}/parsed_owners.csv", 'w+')

	Dir["#{datadir}/owners/*.csv"].each do |ocsv|
    CSV.foreach(ocsv) do |line| 
      if (Release.exists?(:name => line[0])) 
		if (ReleaseFilepath.exists?(:thefilepath => line[1]))
			em = Developer.search_or_add(line[3]) 
			next if (em[0].nil?)
			dev_id = Developer.where(email: em[0]).limit(1).pluck(:id)[0]
			owner_email = em[0]
			release = line[0]
			filepath = line[1]
			directory = line[2]
			owners << [release, filepath, directory, dev_id, owner_email]
		end
		else
		break
      end
    end
	end
    owners.fsync
	ActiveRecord::Base.connection.execute("COPY release_owners FROM '#{tmp}/parsed_owners.csv' DELIMITER ',' CSV")
  end
end
