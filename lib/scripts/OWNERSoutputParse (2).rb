def countCommits
	count = 0
	counts = Array.new
	File.open("practiceOutput.txt").each do |line|
		if (line.include? "::::") 
			puts "Over the course of one year, this file has had " + count.to_s + " commits"
			puts ""
			counts.push(count)
			count = 0
			puts line.slice(5, line.length - 12)
			newFile = true
		elsif (line.index(",") == 3)
			puts "This file was created on " + line.slice(0, line.length - 15)
		elsif (line.include? "/")
			#if (newFile)
			#	ary = Array.new
			#	newFile = false
			#end
			#sum = 0
			count += 1
			#ary.push(line.split("\t")[1].to_i)
			#ary.each { |a| sum+=a }

		end
	end
	puts "Over the course of one year, this file has had " + count.to_s + " commits"
	counts.push(count)
	puts ""
	puts "The average number of commits on an OWNERS file per year is " + (counts.inject{ |sum, el| sum + el }.to_f / counts.size).to_s
end

def ownersAndAuthors
	list = Array.new
	File.open("AUTHORS").each do |line|
		line.chomp!
		if (line[0] != "#") 
			if (line.index(">") != nil)
				list.push(line.slice(line.index("<") + 1, (line.index(">")-line.index("<") -1)))
			end
		end
	end

	puts list.sort
end

def getOwners
	list = Array.new
	File.open("search.txt").each do |line|
		line.chomp!
		File.open(line).each do |name|
			name.chomp!
			if (name[0] != "#")
				if (name.index("=") != nil) 
					name = name.slice(name.index("=") + 1, name.length)
				end
				if (name[0] != "*")
					if (name.index("@") != nil)
						if (!list.include?(name))
							list.push(name)
						end
					end
				end
			end
		end
	end
	puts list.sort
end

def compareLists
	list = Array.new
	count = 0
	File.open("committersAlphabetical.txt").each do |author|
		own = false
		File.open("allTheOwners.txt").each do |owner|
			author.chomp!
			owner.chomp!
			if (owner === author)
				#list.push(owner + " has committed in the past year")
				own = true
			#else
			#	if (!list.include? owner)
			#		list.push(owner)
			#	end
			end
		end
		if (!own)
			list.push(author)
		end
		count += 1
	end

	puts "The total number of commiters in the last year that are not owners are: " + list.size.to_s
	puts "The total number of authors in general are: " + count.to_s
	puts list
end

def sortCommitters
	c = Array.new
	File.open("committers.txt").each do |line|
		line.chomp!
		if (!c.include? line) 
			c.push(line)
		end
	end
	return c.sort
end

def totalCommitters
	c = sortCommitters
	counts = sortCommitters
	totals = Array.new(c.size)
	j = 0

	totals.each do |t| 
		totals[j] = 0
		j += 1
	end

	File.open("committers.txt").each do |line|
		c.each do |com|
			line.chomp!
			com.chomp!
			if (line === com)
				i = c.index(line)
				counts[i] << "*"
				totals[i] += 1
			end
		end
	end
	
	k = 0
	while k < c.size do
		puts c[k].to_s + ": " + totals[k].to_s
		k += 1
	end

end

def compareListsTwo
	list = Array.new
	count = 0
	File.open("allTheOwners.txt").each do |author|
		own = false
		File.open("committersAlphabetical.txt").each do |owner|
			author.chomp!
			owner.chomp!
			if (owner === author)
				#list.push(owner + " has committed in the past year")
				own = true
			#else
			#	if (!list.include? owner)
			#		list.push(owner)
			#	end
			end
		end
		if (!own)
			list.push(author)
		end
		count += 1
	end

	puts "The total number of commiters in the last year that are not owners are: " + list.size.to_s
	puts "The total number of authors in general are: " + count.to_s
	puts list
end

compareListsTwo