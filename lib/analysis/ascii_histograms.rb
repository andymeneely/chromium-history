require 'aggregate'

class ASCIIHistograms
  def run
    puts "@@@ Messages per CodeReview Histogram @@@"
    a = Aggregate.new(0,500,5)
    Message.group(:code_review_id).count.each do |id,count|
      a << count
    end
    puts a.to_s
    puts "\n"
    puts "@@@ Comments per CodeReview Histogram @@@"
    a = Aggregate.new(0,50,1)
    CodeReview.joins(patch_sets: [patch_set_files: :comments]).group(:issue).count.each do |id,count|
      a << count
    end
    puts a.to_s(120)
    puts "\n"
    puts "@@@ PatchSets per CodeReview Histogram @@@"
    a = Aggregate.new(0,50,1)
    PatchSet.group(:code_review_id).count.each do |id,count|
      a << count
    end
    puts a.to_s
    puts "\n"
    puts "@@@ Reviewers per CodeReview Histogram @@@"
    a = Aggregate.new(0,50,1)
    Reviewer.group(:issue).count.each do |id,count|
      a << count
    end
    puts a.to_s
    puts "@@@ Max Churn per CodeReview Histogram @@@"
    a = Aggregate.new(0,1000,10)
    CodeReview.find_each do |c|
      mc = c.max_churn
      a << mc if !mc.nil?
    end
    puts a.to_s(120)
    puts "\n"
    puts "@@@ Number Non-participating Reviewers per CodeReview Histogram @@@"
    a = Aggregate.new(0,50,1)
    CodeReview.find_each do |c|
      np = c.nonparticipating_reviewers.count
      a << np
    end
    puts a.to_s
    puts "\n"
    puts "@@@ Distinct Reviewers per Filepath Histogram @@@"
    a = Aggregate.new(0,100,1)
    Filepath.reviewers\
      .group('filepaths.filepath')\
      .count('distinct(reviewers.dev_id)')\
      .each do |filepath,count|
        a << count
      end
      puts a.to_s
      puts "@@@ Distinct Participants per Filepath Histogram @@@"
      a = Aggregate.new(0,100,1)
      Filepath.participants\
        .group('filepaths.filepath')\
        .count('distinct(participants.dev_id)')\
        .each do |filepath,count|
          a << count
      end
          puts a.to_s
          puts "@@@ Vulnerability Fixes Over Time Histogram @@@"
          dates = CodeReview.joins(:cvenums).order(:created).pluck(:created)
          low = dates.first.to_i
          high = dates.last.to_i
          inc = (high-low)/50
          high = low + 50*inc #integer rounding...
          if low < high
            a = Aggregate.new(low,high,inc)
            dates.each{|d| a << d.to_i}
            str = ''
            a.to_s.each_line do |line|
              if line[/^\d{9}/]
                str << DateTime.strptime(line[0..9], '%s').strftime('%F') << " #{line}\n"
              else
                str << " "*11 << line << "\n"
              end
            end
            puts str
          end
          puts "@@@ Max Churn per CodeReview Histogram @@@"
          a = Aggregate.new(0,1000,10)
          CodeReview.all.find_each do |c|
            mc = c.max_churn
            a << mc if !mc.nil?
          end
          puts a.to_s(120)
          puts "\n"
          puts "@@@ Code Reviews that fall below or over 200 Lines of Code per Hour (0=false, 1=true) @@@"
          a = Aggregate.new(0, 2, 1)
          CodeReview.all.find_each do |c|
            a << (c.loc_per_hour_exceeded? ? 1 : 0)
          end
          puts a.to_s(120)
          puts "\n"
          puts "@@@ ReleaseFilepath perc_sec_experienced_participants @@@"
          a = Aggregate.new(0, 100, 5)
          ReleaseFilepath.all.find_each do |rf|
            a << rf.perc_security_experienced_participants * 100.0
          end
          puts a.to_s(120)
          puts "\n"
          puts "@@@ ReleaseFilepath perc_overlooked_patchsets @@@"
          a = Aggregate.new(0, 100, 5)
          ReleaseFilepath.all.find_each do |rf|
            a << rf.perc_overlooked_patchsets * 100.0
          end
          puts a.to_s(120)
          puts "\n"
          puts "@@@ ReleaseFilepath num_bugs @@@"
          a = Aggregate.new(0,100,1)
          ReleaseFilepath.all.find_each do |rf|
            a << rf.num_bugs
          end
          puts a.to_s(120)
          puts "\n"
  end#histograms
end
