def getOwners
	ownersMasterList = Array.new
	File.open("search.txt").each do |fil|
		File.open("chromium/" + fil.chomp).each do |line|
			#if the owner is not currently in the list, add him
			if line.include? "="
				line = line.slice(line.index("=")+1, line.length)
			end
			line.chomp!
			if not ownersMasterList.include? line
				if not line.include? "#"
					if not line.include? "*"
						if line.include? "@"
							ownersMasterList.push(line)
						end
					end
				end
			else
				#puts line
			end
		end
	end

	return ownersMasterList.sort
end

def countOwners
	ownersMasterList = getOwners
	ownersSTARS = getOwners
	#puts ownersSTARS
	File.open("search.txt").each do |fil|
		File.open("chromium/" + fil.chomp).each do |line|
			if line.include? "="
				line = line.slice(line.index("=")+1, line.length)
			end
			line.chomp!
			#puts line
			if ownersMasterList.include? line
				#puts line + "****got in"
				#if the line (an owner) is included in the master file, then....
				ind = ownersMasterList.index(line) #get the line that its on
				#puts ind
				var = ownersSTARS[ind] #get that line 
				#puts "!!!!!!!!!!!!!!!!!!"
				#puts var
				var << "*"
				ownersSTARS[ind] = var
				#puts ownersSTARS[ind]

			else
				#puts line + "#######didnt"
			end
		end
	end
	puts ownersSTARS
end


def finalCounts
	counts = Array.new
	File.open("stars.txt").each do |line|
		puts line.slice(0, line.index("*")).to_s + " is an owner on " +  line.count("*").to_s + " files"
		counts.push(line.count("*"))
	end
	puts ""
	puts "The average number of times a name appears is: " + (counts.inject{ |sum, el| sum + el }.to_f / counts.size).to_s
	puts ""
	puts counts
end

finalCounts
