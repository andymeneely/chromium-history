# For each file in a given release, populate the necessary metrics
class ReleaseAnalysis

  def populate
    Release.all.each do |r|
      populate_num_reviews(r)
      r.release_filepaths.find_each do |rf|
        rf.num_reviewers = rf.filepath.reviewers(r.date).size
        rf.num_participants  = rf.filepath.participants(r.date).size
        rf.perc_three_more_reviewers = rf.filepath.perc_three_more_reviewers(r.date)
        rf.perc_security_experienced_participants  = rf.filepath.perc_security_exp_part(r.date)
        rf.avg_security_experienced_participants = rf.filepath.avg_security_exp_part(r.date)
        rf.avg_non_participating_revs  = rf.filepath.avg_non_participating_revs(r.date)
        rf.avg_reviews_with_owner  = rf.filepath.avg_reviews_with_owner(r.date)
        rf.avg_owner_familiarity_gap = rf.filepath.avg_owner_familiarity_gap(r.date)
        rf.perc_fast_reviews = rf.filepath.perc_fast_reviews(r.date)
        rf.perc_overlooked_patchsets = rf.filepath.perc_overlooked_patchsets(r.date)
        rf.avg_sheriff_hours = rf.filepath.avg_sheriff_hours(r.date)
        # rf.num_commits = rf.filepath.commits(r.date).size
        # rf.num_major_contributors = rf.filepath.num_major_contributors(r.date).size
        # rf.num_minor_contributors = rf.filepath.num_minor_contributors(r.date).size
        
        rf.vulnerable = rf.filepath.vulnerable?
        rf.num_vulnerabilities = rf.filepath.cves().count

        #effect reach for bugs and vulnerabilities
        effect_reach = 1.years

        #pre_ metrics for bugs
        reach_date = r.date - effect_reach
        dates = reach_date..r.date
        rf.num_pre_bugs = rf.filepath.bugs(dates).count
        rf.num_pre_features = rf.filepath.bugs(dates,'type-feature').count
        rf.num_pre_compatibility_bugs = rf.filepath.bugs(dates,'type-compat').count
        rf.num_pre_regression_bugs = rf.filepath.bugs(dates,'type-bug-regression').count
        rf.num_pre_security_bugs = rf.filepath.bugs(dates,'type-bug-security').count
        rf.num_pre_tests_fails_bugs = rf.filepath.bugs(dates,'cr-tests-fails').count
        rf.num_pre_stability_crash_bugs = rf.filepath.bugs(dates,'stability-crash').count
        rf.num_pre_build_bugs = rf.filepath.bugs(dates,'build').count
        rf.num_pre_vulnerabilities = rf.filepath.cves(dates).count
        rf.was_buggy = rf.num_pre_bugs > 0
        rf.was_vulnerable = rf.filepath.vulnerable?(dates)

        #post_ metrics
        reach_date = r.date + effect_reach
        dates = r.date..reach_date
        rf.num_post_bugs = rf.filepath.bugs(dates).count
        rf.num_post_vulnerabilities = rf.filepath.cves(dates).count
        rf.becomes_buggy = rf.num_post_bugs > 0
        rf.becomes_vulnerable = rf.filepath.vulnerable?(dates)

        rf.save
      end
    end
  end

  def populate_num_reviews(release)
    update = <<-EOSQL
      WITH code_review_counts AS (
        SELECT filepaths.filepath, count(*) AS num_code_reviews
        FROM filepaths INNER JOIN commit_filepaths ON commit_filepaths.filepath = filepaths.filepath
                       INNER JOIN commits ON commits.commit_hash = commit_filepaths.commit_hash
                       INNER JOIN code_reviews ON code_reviews.commit_hash = commits.commit_hash
        WHERE "code_reviews"."created" BETWEEN '1970-01-01 00:00:00' AND '#{release.date}'
        GROUP BY filepaths.filepath
      )
      UPDATE release_filepaths
        SET num_reviews = num_code_reviews
        FROM code_review_counts
        WHERE release_filepaths.thefilepath = code_review_counts.filepath
              AND release_filepaths.release = '#{release.name}'
    EOSQL
    ActiveRecord::Base.connection.execute update
  end

  def populate_num_participants(release)

  end

end
