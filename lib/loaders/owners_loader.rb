require 'csv'

class OwnersLoader

  def load
    datadir = File.expand_path(Rails.configuration.datadir)
    tmp     = Rails.configuration.tmpdir
    owners  = CSV.open("#{tmp}/parsed_owners.csv", 'w+')
    Dir["#{datadir}/owners/*.csv"].each do |ocsv|
      CSV.foreach(ocsv) do |line|
        dev = Developer.search_or_add(line[3])
        if dev.nil?
          unless line[3].eql? "ALL" #skip ALLs in our analysis for now
            $stderr.puts "INVALID EMAIL for Release Owner #{line[3]}"
          end
          next
        end
        release   = line[0]
        filepath  = line[1]
        directory = line[2]
        owners << [release,
                   filepath,
                   directory,
                   dev.id,
                   dev.email,
                   nil, # first_ownership_sha
                   nil, # first_ownership_date
                   nil, # first_file_commit_sha
                   nil, # first_file_commit_date
                   nil, # file_commits_to_ownership
                   nil] # file_commits_to_release
      end
      owners.fsync
      PsqlUtil.copy_from_file 'release_owners', "#{tmp}/parsed_owners.csv"
    end
  end
end
