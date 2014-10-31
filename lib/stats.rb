
class Stats

  def run_all
    puts "=== Summary Statistics ==="
    puts "|"
    code_review_stats
    commit_stats
    bug_stats
    filepath_stats
    developer_stats
    cve_stats
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
    show overlooked_stats, "Code Reviews with an overlooked patchset"
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
    show CommitBug.count, "Commit-Bugs"
    puts "|"
  end

  def bug_stats
    puts "--Bugs"
    show Bug.count, "Bugs"
    show Label.count, "Labels"
    show BugLabel.count, "Bug-labels"
    show BugComment.count, "Bug Comments"
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
    show SheriffRotation.count, "Sheriff rotations"
    show SheriffRotation.sum(:duration), "Total Sheriff rotation hours"
    show SheriffRotation.count(:dev_id, distinct: true), "Developers who have been a sheriff"
    show SheriffRotation.sum(:duration).to_f / SheriffRotation.distinct.count(:dev_id).to_f, "Avg sheriff hours per developer"
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

end#class
