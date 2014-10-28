require "csv"

#
# A scraper to find the time a person was initially added as an OWNER
# 
# @author Danielle Neuberger
class FirstOwnershipScript
  #class-level variable containing hash of owners information
  @@hashmap

  # Create a new isntance
  # @return FirstOwnershipScript instance - the new object
  def initialize()
    @csvLoc = ".."
  end

  def get_ownership()
    #Get all commits with git log command
    log = `git log --all -- '*OWNERS'`
    puts log #TODO call analyze_commit_file for each commit num returned
    
  end

  # Checks out the commit and opens the file, gathers all the
  # owners emails and puts the information along with the commit hash
  # , path, and date into the owner-ownerfile hash
  def analyze_commit_file(commitNum)
    files = `git checkout #{commitNum}`
    date = `git show -s --format%ci #{commitNum}` #TODO %cd vs %ci ?
    files.each do |file|
      puts file #see what the file name is - how do we get the directory?
      if file=="OWNERS" #if the file is an owners file
        get_owners_info(file, commitNum, date) #TODO might need to get file dir for here
      end
    end
  end

  # Open up an owners file and add information to the hash
  def get_owners_info(file, commitNum, date)
    File.foreach(file) do |line|
      if contains_email(line)
	email = line.match(/^[^=][a-z0-9_-]+@[a-z0-9.-]+\.[a-z]{2,4}$/) #TODO test this regex
	directory = "" #TODO get this
 	key = email + "~" + directory
	value = [commitNum, date]
        if @@hashmap.key?(key)
	  currHashDate = @@hashmap[key][0]
	  if date < currHashDate #TODO may need to use Date.parse?
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
    CSV.open(@csvLoc, "a") do |cfile|
      @@hashmap.each do |key, val|
	emailAndDir = key.split(/~/)
        cfile << [emailAndDir[0],emailAndDir[1],val[0]]
      end
    end
  end
end


#driver code
f = FirstOwnershipScript.new()
f.get_ownership()

puts "Done."
