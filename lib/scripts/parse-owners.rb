#!/usr/bin/ruby
require	"pathname"
require "csv"
require "trollop"

#Trollop command-line options
opts = Trollop::options do
  version "OWNERS data collection script"
  banner <<-EOS

The OWNERS scraper/parser iterates over OWNERS files within Chromium source code in the location specified in options. Uses OWNERS rules to develop a a CSV of OWNERS and the files they are responsible for.

Produces a CSV in directory specified in options. Includes version, filename, owner.

Usage: 
  ruby #{File.basename(__FILE__)} [options]

where [options] are:
EOS
  opt :src, "The directory of the Chromium source code to parse", default: ".", type: String
  opt :csv, "The output csv file for the results", default: "owners.csv", type: String
  opt :release, "The name of the release to be stored", default: '11.0',type: String 
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
    File.open(opts[:csv], 'w+').close
    @csvLoc = File.expand_path(opts[:csv])
    @srcLoc = File.expand_path(opts[:src])
    @release = opts[:release]
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

  # For just an email entry
  def addFileOwnersToCsv(files, owners)
    CSV.open(@csvLoc, "a") do |cfile|
      files.each do |filename|
        owners.each do |owner|
          if (self.source_code? filename)
            cfile << [@release,"#{filename}","#{owner[1]}/","#{owner[0]}"]
          end
        end
      end
    end
  end

  # For per-file rules that glob files
  def addSingleFileOwnerToCsv(files, owner, glob)
    CSV.open(@csvLoc, "a") do |cfile|
      #add each version, filename, owner to csv
      (files).each do |filename|
        if File.fnmatch(glob, filename) and (self.source_code? filename)
          cfile << [@release,"#{filename}","#{owner[1]}/","#{owner[0]}"]
        end
      end
    end
  end

  def source_code? filepath
    valid_extns = ['.h','.cc','.js','.cpp','.gyp','.py','.c','.make','.sh','.S''.scons','.sb','Makefile']
    valid_extns.each { |extn| if filepath.to_s.end_with?(extn) then return true end }
    return false
  end


  # Initial call to the recursive function
  def run_parser
    getOwnerShip([], @srcLoc)
  end


  # Recursive call on the directories
  def getOwnerShip(pOwners, currDir)

    allFiles = Array.new

    Dir.chdir currDir do

      #get immediate files in current directory, get relative paths if not baseDir
      allFiles = Dir.entries('.').select {|f| !File.directory? f}
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

        when /^\*$/	#i.e. the entire line is just *
          currOwners << ["ALL", Pathname.new(Dir.pwd).relative_path_from(Pathname.new(@srcLoc))]

        when /^[^=][a-z0-9_-]+@[a-z0-9.-]+\.[a-z]{2,4}$/
          rule.slice!(-1)
          currOwners << [rule, Pathname.new(Dir.pwd).relative_path_from(Pathname.new(@srcLoc))]

        when rule.slice(0).eql?("#") , rule.eql?("\n") #ignore whitespace and comments
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
          #comments and whitespace do nothing
        when /per-file.+=.*\*/
          glob = (rule.split("=")[0]).sub("per-file ","")
          email = ["ALL", Pathname.new(Dir.pwd).relative_path_from(Pathname.new(@srcLoc))]
          addSingleFileOwnerToCsv(allFiles+noPFiles, email, glob)

        when /per-file.*set noparent/
          glob = (rule.sub("=set noparent", "")).sub("per-file ","")
          setFilesWithNoParents(allFiles, noPFiles, glob)

        when /per-file.+@.+/
          rule.slice!(-1)
          glob = (rule.split("=")[0]).sub("per-file ","")
          email = [rule.sub("per-file "+glob+"=",""), Pathname.new(Dir.pwd).relative_path_from(Pathname.new(@srcLoc))]
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
p.run_parser

puts "Done."

