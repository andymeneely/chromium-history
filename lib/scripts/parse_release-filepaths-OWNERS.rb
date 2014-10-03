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
  
  def getRelativePath (filename)
	relative = Pathname.new(Dir.pwd).relative_path_from Pathname.new(@srcLoc)
	filename = relative.to_s + "/" + filename
    return filename
  end
  
  def setFilesWithNoParents(allFiles, noPFiles, glob)
	allFiles.each do |filename|
			if File.fnmatch(glob, filename)
				noPFiles << filename
				allFiles.delete(filename)
			end
		end
  end
  
  def addFileOwnersToCsv(files, owners)
  CSV.open(@csvLoc, "a") do |cfile|
  files.each do |filename|
        owners.each do |owner|
           cfile << ["11","#{filename}", "#{owner}"]
        end
      end
	  end
  end
  
  def addSingleFileOwnerToCsv(files, owner, glob)
  CSV.open(@csvLoc, "a") do |cfile|
  #add each version, filename, owner to csv
	  (files).each do |filename|
	    if File.fnmatch(glob, filename)
	      cfile << ["11","#{filename}", "#{owner}"]
	    end
	  end
	  end
  end

  def getOwnerShip(pOwners, currDir)
    
	allFiles = Array.new
	
    Dir.chdir currDir do
	
    #get immediate files in current directory, get relative paths if not baseDir
    allFiles = Dir.glob("*.*")
	(allFiles.map! {|f| getRelativePath(f)}) if !(Dir.pwd.to_s.eql?(@srcLoc))
	
	currOwners = Array.new
	rules = Array.new
	
	#get the new owners: currOwners from OWNERS file in current directory if there is one : currDir
	rules = File.open("OWNERS").readlines if File.file?("OWNERS")
	index = -1
	
	rules.each_with_index do |rule, i|
	index = i
	case rule
	
	when  /^set noparent/
	pOwners = Array.new
	
	when /^\*$/	#rule.eql?("*\n")
	currOwners << "ALL"
	
	when /^[^=][a-z0-9_-]+@[a-z0-9.-]+\.[a-z]{2,4}$/
	rule.slice!(-1)
	currOwners << rule
	
	when rule.slice(0).eql?("#") , rule.eql?("\n")
	when /per-file.+/
	break
	
	end
	
	end
	
	#send currOwners to all immediate sub-directories, so their files know who are their parents, get all childFiles in return
    childFiles = Array.new
    Dir.glob("*/").each {|nxtDir| childFiles += getOwnerShip(pOwners+currOwners,nxtDir )}
	
	#all files under this directory
    allFiles += childFiles
	noPFiles = Array.new  #for files that have no parent
	
	rules.drop(index).each do |rule|
	case rule
	when rule.slice(0).eql?("#") , rule.eql?("\n")
	#do nothing
	when /per-file.+=.*\*/
	glob = (rule.split("=")[0]).sub("per-file ","")
	email = "ALL"
	addSingleFileOwnerToCsv(allFiles+noPFiles, email, glob)
	
	when /per-file.*set noparent/
	glob = (rule.sub("=set noparent", "")).sub("per-file ","")
	setFilesWithNoParents(allFiles, noPFiles, glob)
	
	when /per-file.+@.+/
	rule.slice!(-1)
	glob = (rule.split("=")[0]).sub("per-file ","")
	email = rule.sub("per-file "+glob+"=","")
	addSingleFileOwnerToCsv(allFiles+noPFiles, email, glob)
	
	end
	end unless index == -1 || index+1 >= rules.length
	
	#add each version, filename, owner to csv for global owners
	addFileOwnersToCsv(allFiles, currOwners+pOwners )
	
     
	end
	
	return (pOwners.empty?)? Array.new : allFiles
	
	end
	end
	
#driver code
p = ParseReleaseFilepathsOwners.new(opts)
p.getOwnerShipHelper

puts "Done."

