require "rubygems"
require	"pathname"
require "csv"
require "trollop"

#Trollop command-line options
opts = Trollop::options do
  version "OWNERS Scraper 1.0"
  banner <<-EOS

The OWNERS scraper/parser iterates over OWNERS files within Chromium source code in the location specified in options. Uses OWNERS rules to develop a a CSV of OWNERS and the files they are responsible for.

Produces a CSV in directory specified in options. Includes version, filename, owner.

Usage: 
  ruby parse_release-filepaths-OWNERS.rb [options]
where [options] are:
EOS
  opt :srcLocation, "The location of the Chromium source code to parse", default:"..", type: String
  opt :csvOutputLocation, "The location for where to place the CSV results", default:"..", type: String
end

#
# A parser for gathering OWNERship information from Chromium source code.
#
# @author Richard Kalimba
# @author Danielle Neuberger
class ParseReleaseFilepathsOwners
  
  # Create a new instance
  # @param initial=nil Hash The initial values we have. 
  # @return ParseReleaseFilepathsOwners The new object
  def initialize(opts)
    @opts = opts
    @csvLoc = @opts[:csvOutputLocation]
    @srcLoc = @opts[:srcLocation]
  end

  def getSrcLoc()
    return @srcLoc
  end

  def getOwnerShipHelper(csvLoc=@opts[:csvOutputLocation], srcLoc = @opts[:srcLocation])
    @csvLoc = csvLoc
    @srcLoc = srcLoc
    getOwnerShip(Array.new, srcLoc)
  end

  def getOwnerShip(pOwners, currDir)
    #change to currDir
    Dir.chdir currDir
    currOwners = Array.new
    cfile = CSV.open(@csvLoc, "a")

    #get immediate files in current directory
    allFiles = Dir.glob("*.*")

    #get relative paths if not baseDir
    if (allFiles.respond_to?("each") and !(Dir.pwd.to_s.eql?(@srcLoc)))
      relative = Pathname.new(Dir.pwd).relative_path_from Pathname.new(@srcLoc)
      allFiles.map!  {|filename| filename = relative.to_s + "/" + filename}
    end

    #get the new owners: currOwners from OWNERS file in current directory if there is one : currDir
    if File.file?("OWNERS.txt")
      f = File.open("OWNERS.txt")

      #Process the owners file
      #if it has set noparent as first rule in file, drop pOwners. currOwners only are to own sub directories. if all are owners record that too
      rule = f.readline
      if rule.eql?("set noparent\n")
        pOwners = Array.new
        rule = f.readline
      elsif rule.eql?("*\n")
        currOwners << "ALL"
        rule = f.readline
      end
      rule = rule.sub("\n", "")

      #add all emails at beginning to currOwners until per-file rule is met.
      until (rule.include?("per-file")  or f.eof?) do
        currOwners << rule
        rule = f.readline
        #if comment or blank, get next
        while (rule.slice(0).eql?("#") or rule.eql?("\n"))
          rule = f.readline
        end
        rule = rule.sub("\n", "")
      end

      #send currOwners to all immediate sub-directories, so their files know who are their parents, get all childFiles in return
      childFiles = Array.new
      if Dir.glob("*/").respond_to?("each")
        Dir.glob("*/").each {|nxtDir| childFiles += getOwnerShip(pOwners+currOwners,nxtDir )}
        #will store childFiles returned to be included for per-file rules.
      end

      #all files under this directory
      allFiles += childFiles

      noPFiles = Array.new  #for files that have no parent

      #process per-file rules
      until (!(rule.include?("per-file")) or f.eof?) do
        fileRule  = rule

        #if per-file rule has set noparent, then get the globbed files to a new list of files without parents
        if rule.include?("set noparent")
    	  glob = (rule.sub("=set noparent", "")).sub("per-file ","")

	  allFiles.each do |filename|
            if File.fnmatch(glob, filename)
	      noPFiles << filename
	      allFiles.delete(filename)
	    end
	  end

        else
	  #if per-file rule has email of owner, add to csv all files from allFiles or noPFiles matching glob
	  glob = (rule.split("=")[0]).sub("per-file ","")
	  email = rule.sub("per-file "+glob+"=","")
	  if email.eql?("*")
	    email = "ALL"
	  end
	  #add each version, filename, owner to csv
	  (allFiles+noPFiles).each do |filename|
	    if File.fnmatch(glob, filename)
	      cfile << ["11","#{filename}", "#{email}"]
	    end
	  end

        end

        rule = f.readline
        #if comment or blank, get next
        while (rule.slice(0).eql?("#") or rule.eql?("\n"))
	  rule = f.readline
        end
        rule = rule.sub("\n", "")

      end

      #add each version, filename, owner to csv for global owners
      allFiles.each do |filename|
        (currOwners+pOwners).each do |owner|
           cfile << ["11","#{filename}", "#{owner}"]
        end
      end

      f.close
    end

    cfile.close
    Dir.chdir("..")

    if (pOwners.empty?)
      return Array.new
    else
      return allFiles 
    end

  end

end

#driver code
p = ParseReleaseFilepathsOwners.new(opts)
p.getOwnerShipHelper

puts "Done."
