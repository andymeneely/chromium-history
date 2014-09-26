require "rubygems"
require	"Pathname"
require "csv"

#address of src & csv
$SRCDir = ".." 
$CSVFile = ".."

def getOwnerShip(pOwners, currDir)

	#change to currDir
	Dir.chdir currDir
	currOwners = Array.new
	cfile = CSV.open($CSVFile, "a")

	#get immediate files in current directory
	allFiles = Dir.glob("*.*")

	#get relative paths if not baseDir
	if (allFiles.respond_to?("each") and !(Dir.pwd.to_s.eql?($SRCDir)))
		relative = Pathname.new(Dir.pwd).relative_path_from Pathname.new($SRCDir)
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

getOwnerShip(Array.new, $SRCDir)
