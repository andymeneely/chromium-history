require "csv"

#
# A scraper to find the time a person was initially added as an OWNER
# 
# @author Danielle Neuberger
class FirstOwnershipScript

  # Create a new isntance
  # @return FirstOwnershipScript instance - the new object
  def initialize()
    @csvLoc = ".."
  end

  def get_ownership()
    #Get all commits with git log command
    log = `git log --all -- '*OWNERS.txt'`
    puts log
    
  end

  # Checks out the commit and opens the file, gathers all the
  # owners emails and puts the information along with the commit hash
  # , path, and date into the owner-ownerfile hash
  def analyze_commit_file(commitNum)
    files = `git checkout ` + commitNum
    files.each do |file|
      if file=="OWNERS.txt" #if the file is an owners file
        parse_owners_file(file, commitNum)
      end
    end
  end

  # Open up an owners file and add information to the hash
  def get_owners_info(file, commitNum)
    

  end

  # Add information to the CSV file
  def create_csv()
    CSV.open(@csvLoc, "a") do |cfile|
      #add email, directory, first-owner-commit id to csv
      
      cfile << []
    end
  end
end


#driver code
f = FirstOwnershipScript.new()
f.get_ownership()

puts "Done."
