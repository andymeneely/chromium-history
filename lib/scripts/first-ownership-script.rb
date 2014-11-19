require "csv"
require "trollop"

# Trollop Command-line parameters
opts = Trollop::options do
  version "First OWNERShip script"
  banner <<-EOS

The first ownership script takes in a text file of commit hashes (separated by new lines) for commits that have modified any OWNERS file. 

Produces a CSV including developer email, directory of OWNERS file, and commit hash for when the developer was first added to the OWNERS file.

Usage: 
  ruby #{File.basename(__FILE__)} [options]

where [options] are:
  EOS
  opt :commitsFile, "The file name including path of the file containing the commit hashes to use", :required => true, type: String
  opt :csv, "The output CSV file for the results", default: "../first-owners.csv", type: String
end 


#
# A scraper to find the time a person was initially added as an OWNER
# 
# @author Danielle Neuberger
class FirstOwnershipScript
  @@hashmap # hash of owners info with key: email~path, value: [commitNum, date]
  @@commitNumsFile # the file name for the commit hashes modifying OWNERS files
  @@csvLoc # the location of the CSV file to produce

  # Create a new isntance
  # @return FirstOwnershipScript instance - the new object
  def initialize(opts)
    File.open(opts[:csv], 'w+').close
    @@commitNumsFile = File.expand_path(opts[:commitsFile])
    @@csvLoc = File.expand_path(opts[:csv])
    @@hashmap = Hash.new(0)
  end

  # Method to loop through commit nums in the passed file and call helper methods
  # to pull information for each 
  def get_ownership()    
    File.readlines(@@commitNumsFile).each do |line|
      analyze_commit_file(line) #assumes each line has only the commit hash
    end
    create_csv()
  end

  # Checks out the commit and opens the file, gathers all the
  # owners emails and puts the information along with the commit hash
  # , path, and date into the owner-ownerfile hash
  def analyze_commit_file(commitNum)
    filesWithPaths = `git diff-tree --no-commit-id --name-only -r #{commitNum}`.split(/\n/)
    date = `git show -s --format=%ci #{commitNum}`
    filesWithPaths.each do |file|
      if file.include? "OWNERS"  #if the file is an owners file
	path = File.dirname(file) + "/" #format path to just be the directory (eg /chrome/common/OWNERS -> /chrome/common/)
        commitNum = commitNum.strip()
        get_owners_info(file, commitNum, date, path)
      end
    end
  end

  # Open up an owners file and add information to the hash
  def get_owners_info(file, commitNum, date, path)
    ownersText = `git show #{commitNum}:#{file}`
    ownersText.each_line do |line| 
      if line.include? "@" and line.include? "=" # then email is everything after =
	email = line.split('=')[-1]
      elsif line.include? "@" # then email is entire line
	email = line
      end
      if !email.nil? #if there is an email
        key = email + "~" + path
        value = [commitNum, date]
        if @@hashmap.key?(key)
  	  currHashDate = @@hashmap[key][0]
          if date < currHashDate
            @@hashmap[key] = value
          end
        else 
	  @@hashmap[key] = value
        end
      end
    end
  end

  # Add information to the CSV file in format of 
  #  email, directory, commit id
  def create_csv()
    CSV.open(@@csvLoc, "a") do |cfile|
      @@hashmap.each do |key, val|
	emailAndDir = key.split(/~/)
        cfile << [emailAndDir[0],emailAndDir[1],val[0]]
      end
    end
  end
end


#driver code
f = FirstOwnershipScript.new(opts)
f.get_ownership()

puts "Done."
