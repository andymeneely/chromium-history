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

=begin  def overlooked_stats
    total = 0
    CodeReview.find_each do |c|
      total = total + 1 if c.overlooked_patchset?
    end
    return total
  end
=end
  def commit_stats
    puts "--Commits"
    show Commit.count, "Commits"
    show CommitFilepath.count, "Commit-filepaths"
    show Commit.where(code_review_id: nil).count, "Commits without code reviews"
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
    CodeReview.all.find_each do |c|
      mc = c.max_churn
      a << mc if !mc.nil?
    end
    puts a.to_s(120)
    puts "\n"

    puts "@@@ Number Non-participating Reviewers per CodeReview Histogram @@@"
    a = Aggregate.new(0,50,1)
    CodeReview.all.find_each do |c|
      np = c.num_nonparticipating_reviewers
      a << np
    end
    puts a.to_s
    puts "\n"

    puts "@@@ Max Churn per CodeReview Histogram @@@"
    a = Aggregate.new(0,1000,10)
    CodeReview.all.find_each do |c|
      mc = c.max_churn
      a << mc if !mc.nil?
    end
    puts a.to_s(120)
    puts "\n"

    puts "@@@ Number of Vulnerabilities per Participant Inspection Histogram @@@"
    a = Aggregate.new(0, 10, 1)
    Developer.all.find_each do |c|
      nd = c.num_vulnerable_inspects
      a << nd
    end
    puts a.to_s(120)
    puts "\n"

    puts "@@@ Number of Vulnerabilities per Filepath Inspection Histogram @@@"
    a = Aggregate.new(0, 10, 1)
    Filepath.all.find_each do |c|
      vf = c.num_vulnerable_devs
      a << vf
    end
    puts a.to_s(120)
    puts "\n"

    puts "@@@ Code Reviews that fall below or over 200 Lines of Code per Hour (0=false, 1=true) @@@"
    a = Aggregate.new(0, 2, 1)
    CodeReview.all.find_each do |c|
      cl = if c.loc_per_hour_exceeded? then 1 else 0 end
      a << cl  
    end
    puts a.to_s(120)
    puts "\n"

  end#histograms



end#class
