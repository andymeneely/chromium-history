require 'aggregate'

class Stats

  def run_all
    puts "=== Summary Statistics ==="
    puts "|"
    code_review_stats
    commit_stats
    filepath_stats
    developer_stats
    cve_stats
    collaborator_familiarity
    histograms
  end

  def code_review_stats
    puts "--Code Reviews"
    show CodeReview.count, "Code Reviews"
    show Reviewer.count, "Reviewers"
    show Reviewer.count.to_f / CodeReview.count.to_f, "Reviewers per Code Review"
    show Comment.count + Message.count, "Total comments and messages"
    show PatchSet.count, "Patch sets"
    show PatchSetFile.count, "Patch set files"
    show PatchSet.count.to_f / CodeReview.count.to_f, "Patch sets per code review"
    #show overlooked_stats, "Code Reviews with an overlooked patchset"
    puts "|"
  end

  def overlooked_stats
    total = 0
    CodeReview.find_each do |c|
      total = total + 1 if c.overlooked_patchset?
    end
    return total
  end

  def commit_stats
    puts "--Commits"
    show Commit.count, "Commits"
    show CommitFilepath.count, "Commit-filepaths"
    puts "|"
  end

  def filepath_stats
    puts "--Filepaths"
    show Filepath.count, "Filepaths"
    puts "|"
  end

  def developer_stats
    puts "--Developers"
    show Developer.count, "Developers"
    show CodeReview.joins(:reviewers,:cvenums).pluck(:email).uniq.count, "Vulnerability-experienced reviewers"
    puts "|"
  end

  def cve_stats
    puts "--CVEs"
    show Cvenum.count, "CVEs"
    show Cvenum.joins(:code_reviews).count, "CVE-fixing inspections"
    puts "|"
  end

  def show(stat,desc)
    printf "|%9.2f %s\n", stat, desc if stat.is_a? Float
    printf "|%9d %s\n", stat, desc if stat.is_a? Integer
  end

  def collaborator_familiarity
    total = 0
    #CodeReview.find_each do |c|
      #FIXME Don't output, put in a histogram
      #puts "Total Familiarity: #{c.total_familiarity}"
      #puts "Average Familiarity: #{c.average_familiarity}"
    #end
    return total
  end

  def histograms
    # TODO Refactor this out to its own file called by rake
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


    puts "@@@ Distinct Contributors per Filepath Histogram @@@"
    a = Aggregate.new(0,100,1)
    Filepath.contributors\
      .group('filepaths.filepath')\
      .count('distinct(contributors.dev_id)')\
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
  
    puts "@@@ Max Churn per CodeReview Histogram @@@"
    a = Aggregate.new(0,1000,10)
    CodeReview.all.find_each do |c|
      mc = c.max_churn
      a << mc if !mc.nil?
    end
    puts a.to_s(120)
    puts "\n"

    # FIXME Slow query
    #puts "@@@ Number of Vulnerabilities per Participant Inspection Histogram @@@"
    #a = Aggregate.new(0, 10, 1)
    #Developer.all.find_each do |c|
    #  nd = c.num_vulnerable_inspects
    #  a << nd
    #end
    #puts a.to_s(120)
    #puts "\n"

    #FIXME This is broken too
    #puts "@@@ Number of Vulnerability Participants per Filepath Inspection Histogram @@@"
    #a = Aggregate.new(0, 10, 1)
    #Filepath.all.find_each do |c|
    #  vf = c.num_vulnerable_devs
    #  a << vf
    #end
    #puts a.to_s(120)
    #puts "\n"

    puts "@@@ Code Reviews that fall below or over 200 Lines of Code per Hour (0=false, 1=true) @@@"
    a = Aggregate.new(0, 2, 1)
    CodeReview.all.find_each do |c|
      cl = if c.loc_per_hour_exceeded? then 1 else 0 end
      a << cl  
    end
    puts a.to_s(120)
    puts "\n"

    #FIXME Broken on dev data
    #puts "@@@ Number of Experienced Developers per Code Review Histogram @@@"
    #a = Aggregate.new(0, 10, 1)
    #CodeReview.all.find_each do |c|
    #  cl = c.security_experienced_parts.size
    #  a << cl 
    #end
    #puts a.to_s(120)
    #puts "\n"

    puts "@@@ Total Participator Familiarity per Code Review Histogram @@@"
    a = Aggregate.new(0, 10, 1)
    CodeReview.all.find_each do |c|
      cl = c.total_familiarity
      a << cl 
    end
    puts a.to_s(120)
    puts "\n"

  end#histograms



end#class