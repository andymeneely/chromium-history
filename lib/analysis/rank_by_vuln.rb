require 'rinruby'
require 'utils/rinruby_util'

class RankByVuln
  include RinrubyUtil

  def initialize
    R.echo false, false
    R.eval <<-EOR
      options("width"=250)
    EOR
  end

  def run
    puts "\n=========================="
    puts "=== File Ranking Results ==="
    puts "============================\n"
    summary_stats
    puts ""
    set_up_libraries
    connect_to_db do
      load_release_filepaths
      full_analysis
    end
    R.eval 'save.image()'
  end

  # Set up libraries, including our own custom script
  def set_up_libraries
    R.eval <<-EOR
    EOR
  end

  def save_image

  end

  def summary_stats
    puts "Number of CVEs with bounty: #{Cvenum.where('bounty > 0').count}"
    puts "Avg of bounty (non-zero): $#{Cvenum.where('bounty > 0').average(:bounty)}"
    puts "Max bounty: $#{Cvenum.maximum(:bounty).to_f}"
    puts "Number of release-filepaths with a bounty: #{ReleaseFilepath.where('bounty > 0').count}"
    puts "Total number of bugs on bounty files: #{ReleaseFilepath.where('bounty > 0').sum(:num_pre_bugs)}"
    puts "Total number of bugs: #{ReleaseFilepath.sum(:num_pre_bugs)}"
    puts "Total bounty: $#{Cvenum.sum(:bounty).to_f}"
    puts "Total file-bounty: $#{ReleaseFilepath.sum(:bounty).to_f}"
    Release.order(:date).each do |r|
      puts " File-bounty for Release #{r.name}: $#{ReleaseFilepath.where(release: r.name).sum(:bounty).to_f}"
    end

  end

  def load_release_filepaths
    R.eval <<-EOR
      with_bounties <- dbGetQuery(con,
      "SELECT
        release,
        SLOC,
        num_pre_bugs,
        bounty,
        cvss_base,
        becomes_vulnerable
      FROM release_filepaths
      WHERE SLOC > 0
        AND bounty > 0 ")
    EOR
  end

  def full_analysis
    puts"-----------------------"
    puts"-------Spearman--------"
    puts"-----------------------"
    # R.echo true, false # pretty verbose. Useful for debugging rinruby
    R.eval <<-EOR
      spearman_results <- cor(with_bounties$num_pre_bugs, with_bounties$bounty, method="spearman", use="pairwise.complete.obs")
    EOR
    puts "Overall spearman: #{R.pull("spearman_results")} (n=#{R.pull("length(with_bounties$bounty)")})"
    Release.order(:date).each do |r|
      R.eval <<-EOR
        bugs   <- with_bounties$num_pre_bugs[with_bounties$release=="#{r.name}"]
        bounty <- with_bounties$bounty[with_bounties$release=="#{r.name}"]
        spearman_results <- cor(bugs, bounty, method="spearman", use="pairwise.complete.obs")
      EOR
      puts "RELEASE #{r.name}: #{R.pull("spearman_results")} (n=#{R.pull("length(bounty)")})"
    end

  end
end
