def countCommits
	count = 0
	deletions = 0
	counts = Array.new
	countsWithoutZero = Array.new
	deletionsTotal = Array.new
	File.open("output.txt").each do |line|
		if (line.include? "::::") 
			puts "Over the course of one year, this file has had " + count.to_s + " commits"
			puts ""
			counts.push(count)
			deletionsTotal.push(deletions)
			if (count != 0) 
				countsWithoutZero.push(count)
			end
			count = 0
			deletions = 0
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
			add = (line.split("\t")[0].to_i)
			minus = (line.split("\t")[1].to_i)
			if (minus != 0) 
				puts minus.to_s + " lines deleted"
				deletions += minus
			end
			#ary.each { |a| sum+=a }

		end
	end
	puts "Over the course of one year, this file has had " + count.to_s + " commits"
	counts.push(count)
	puts ""
	puts "Average number of commits in the last year: " + (counts.inject{ |sum, el| sum + el }.to_f / counts.size).to_s
	puts "Average number of commits without zeros " + (countsWithoutZero.inject{ |sum, el| sum + el }.to_f / countsWithoutZero.size).to_s
	puts "Average number deletions per file in one year " + (deletionsTotal.inject{ |sum, el| sum + el }.to_f / deletionsTotal.size).to_s
end

countCommits