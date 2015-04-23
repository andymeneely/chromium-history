# For each file in a given release, populate the necessary metrics
class ReleaseAnalysis

  def populate
    puts "=== Fast Populations ==="
    Release.all.each do |r|
      Benchmark.bm(40) do |x|
        x.report ('Populate num_reviews')   {populate_num_reviews(r)}
        x.report ('Populate churn')         {populate_churn(r)}
        x.report ('Populate num_reviewers') {populate_num_reviewers(r)}
        x.report ('Populate participants')  {populate_participants(r)}
        x.report ('Populate owners data')   {populate_owners_data(r)}
        x.report ('Populate ownership')     {populate_ownership_data(r)}
        x.report ('Zero out the nulls')     {zero_out_the_nulls}
      end
    end
    puts "=== Slow populations ==="
    Benchmark.bm(40) do |x|
      x.report('Slow populations together') do
        Release.all.each do |r|
          r.release_filepaths.find_each do |rf|
            rf.perc_three_more_reviewers = rf.filepath.perc_three_more_reviewers(r.date)
            rf.avg_reviews_with_owner  = rf.filepath.avg_reviews_with_owner(r.date)
            rf.avg_owner_familiarity_gap = rf.filepath.avg_owner_familiarity_gap(r.date)
            rf.perc_fast_reviews = rf.filepath.perc_fast_reviews(r.date)
            rf.avg_sheriff_hours = rf.filepath.avg_sheriff_hours(r.date)

            major_minor_contributors = rf.filepath.contributor_percentage(r.date);
            rf.num_major_contributors = major_minor_contributors[0].size;
            rf.num_minor_contributors = major_minor_contributors[1].size;
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
    end
  end

  def populate_num_reviews(release)
    drop   = 'DROP TABLE IF EXISTS code_review_counts'
    create = <<-EOSQL
      CREATE UNLOGGED TABLE code_review_counts AS (
        SELECT filepaths.filepath, count(*) AS num_code_reviews
        FROM filepaths INNER JOIN commit_filepaths ON commit_filepaths.filepath = filepaths.filepath
                       INNER JOIN commits ON commits.commit_hash = commit_filepaths.commit_hash
                       INNER JOIN code_reviews ON code_reviews.commit_hash = commits.commit_hash
        WHERE code_reviews.created BETWEEN '1970-01-01 00:00:00' AND '#{release.date}'
        GROUP BY filepaths.filepath
      )
    EOSQL
    index  = 'CREATE UNIQUE INDEX index_filepath_on_code_review_counts ON code_review_counts(filepath)'
    update = <<-EOSQL
      UPDATE release_filepaths
        SET num_reviews = code_review_counts.num_code_reviews
        FROM code_review_counts
        WHERE release_filepaths.thefilepath = code_review_counts.filepath
              AND release_filepaths.release = '#{release.name}'
    EOSQL
    ActiveRecord::Base.connection.execute drop
    ActiveRecord::Base.connection.execute create
    ActiveRecord::Base.connection.execute index
    ActiveRecord::Base.connection.execute update
  end

  def populate_major_minor_contributors(release)
    c           = 'commits'
    f           = 'filepaths'
    cf          = 'commit_filepaths'
    cAuthorID   = c+  '.author_id'
    cCreatedAt  = c+  '.created_at'
    cHash       = c+  '.commit_hash'
    fFilepaths  = f+  '.filepath'
    cfFilepaths = cf+ '.filepath'
    cfHash      = cf+ '.commit_hash'
    rName       = release.name

    # totalCommits   = SELECT COUNT(cfFilepaths) FROM cf INNER JOIN c ON cHash = cfHash 
    # totalCommiters = SELECT DISTINCT COUNT(DISTINCT cAuthorID) FROM cf INNER JOIN c ON c.cHash = cfHash
    # userCommits    = SELECT COUNT(*) AS count_all, author_id AS author_id FROM cf INNER JOIN c ON cHash = cfHash GROUP BY author_id

    drop   = 'DROP TABLE IF EXISTS major_minor_counts'
    create = <<-EOSQL
      CREATE UNLOGGED TABLE major_minor_counts AS (
        SELECT filepaths.filepath, count(*) AS num_code_reviews
        FROM filepaths INNER JOIN commit_filepaths ON commit_filepaths.filepath = filepaths.filepath
                       INNER JOIN commits ON commits.commit_hash = commit_filepaths.commit_hash
                       INNER JOIN code_reviews ON code_reviews.commit_hash = commits.commit_hash
        WHERE code_reviews.created BETWEEN '1970-01-01 00:00:00' AND '#{release.date}'
        GROUP BY filepaths.filepath
      )
    EOSQL
    index  = 'CREATE UNIQUE INDEX index_filepath_on_code_review_counts ON major_minor_counts(filepath)'
    update = <<-EOSQL
      UPDATE release_filepaths
        SET num_reviews = major_minor_counts.num_code_reviews
        FROM major_minor_counts
        WHERE release_filepaths.thefilepath = major_minor_counts.filepath
              AND release_filepaths.release = '#{release.name}'
    EOSQL
    ActiveRecord::Base.connection.execute drop
    ActiveRecord::Base.connection.execute create
    ActiveRecord::Base.connection.execute index
    ActiveRecord::Base.connection.execute update
  end
  
  def populate_churn(release)
    drop   = 'DROP TABLE IF EXISTS churn_counts'
    create = <<-EOSQL
      CREATE UNLOGGED TABLE churn_counts AS (
        SELECT filepaths.filepath, count(*) AS num_commits, sum(total_churn) as churn
        FROM filepaths INNER JOIN commit_filepaths ON commit_filepaths.filepath = filepaths.filepath
                       INNER JOIN commits ON commits.commit_hash = commit_filepaths.commit_hash
        WHERE commits.created_at BETWEEN '1970-01-01 00:00:00' AND '#{release.date}'
        GROUP BY filepaths.filepath
      )
    EOSQL
    index  = 'CREATE UNIQUE INDEX index_filepath_on_churn_counts ON churn_counts(filepath)'
    update = <<-EOSQL
      UPDATE release_filepaths
        SET num_commits = churn_counts.num_commits,
            churn       = churn_counts.churn
        FROM churn_counts
        WHERE release_filepaths.thefilepath = churn_counts.filepath
              AND release_filepaths.release = '#{release.name}'
    EOSQL
    ActiveRecord::Base.connection.execute drop
    ActiveRecord::Base.connection.execute create
    ActiveRecord::Base.connection.execute index
    ActiveRecord::Base.connection.execute update
  end

  def populate_num_reviewers(release)
    drop   = 'DROP TABLE IF EXISTS reviewer_counts'
    create = <<-EOSQL
      CREATE UNLOGGED TABLE reviewer_counts AS (
        SELECT filepaths.filepath, count(*) AS num_reviewers
        FROM filepaths INNER JOIN commit_filepaths ON commit_filepaths.filepath = filepaths.filepath
                       INNER JOIN commits ON commits.commit_hash = commit_filepaths.commit_hash
                       INNER JOIN code_reviews ON code_reviews.commit_hash = commits.commit_hash
                       INNER JOIN reviewers ON reviewers.issue = code_reviews.issue
        WHERE code_reviews.created BETWEEN '1970-01-01 00:00:00' AND '#{release.date}'
        GROUP BY filepaths.filepath
      )
    EOSQL
    index  = 'CREATE UNIQUE INDEX index_filepath_on_num_reviewers ON reviewer_counts(filepath)'
    update = <<-EOSQL
      UPDATE release_filepaths
        SET num_reviewers = reviewer_counts.num_reviewers
        FROM reviewer_counts
        WHERE release_filepaths.thefilepath = reviewer_counts.filepath
          AND release_filepaths.release = '#{release.name}'
    EOSQL
    ActiveRecord::Base.connection.execute drop
    ActiveRecord::Base.connection.execute create
    ActiveRecord::Base.connection.execute index
    ActiveRecord::Base.connection.execute update
  end

  def populate_participants(release)
    drop = 'DROP TABLE IF EXISTS participant_counts'
    create = <<-EOSQL
      CREATE UNLOGGED TABLE participant_counts AS (
        SELECT filepaths.filepath, 
               COUNT(*) AS num_participants,
               COUNT( CASE WHEN participants.security_experienced = 't' 
                           THEN 1
                           ELSE null
                      END ) AS num_security_experienced_participants,
               COUNT( CASE WHEN participants.bug_security_experienced = 't' 
                           THEN 1
                           ELSE null
                      END ) AS num_bug_security_experienced_participants,
               COUNT( CASE WHEN participants.stability_experienced = 't' 
                           THEN 1
                           ELSE null
                      END ) AS num_stability_experienced_participants,
               COUNT( CASE WHEN participants.build_experienced = 't' 
                           THEN 1
                           ELSE null
                      END ) AS num_build_experienced_participants,
               COUNT( CASE WHEN participants.test_fail_experienced = 't' 
                           THEN 1
                           ELSE null
                      END ) AS num_test_fail_experienced_participants,
               COUNT( CASE WHEN participants.compatibility_experienced = 't' 
                           THEN 1
                           ELSE null
                      END ) AS num_compatibility_experienced_participants,
               SUM(security_adjacencys) AS security_adjacencys
        FROM filepaths INNER JOIN commit_filepaths ON commit_filepaths.filepath = filepaths.filepath
                       INNER JOIN commits ON commits.commit_hash = commit_filepaths.commit_hash
                       INNER JOIN code_reviews ON code_reviews.commit_hash = commits.commit_hash
                       INNER JOIN participants ON participants.issue = code_reviews.issue
        WHERE code_reviews.created BETWEEN '1970-01-01 00:00:00' AND '#{release.date}'
        GROUP BY filepaths.filepath
      )
    EOSQL
    index = 'CREATE UNIQUE INDEX index_filepath_on_participant_counts ON participant_counts(filepath)'
    update = <<-EOSQL
      UPDATE release_filepaths
        SET num_participants = participant_counts.num_participants,
            num_security_experienced_participants = participant_counts.num_security_experienced_participants,
            avg_security_experienced_participants = participant_counts.num_security_experienced_participants / participant_counts.num_participants,
            num_bug_security_experienced_participants = participant_counts.num_bug_security_experienced_participants,
            avg_bug_security_experienced_participants = participant_counts.num_bug_security_experienced_participants / participant_counts.num_participants,
            num_stability_experienced_participants = participant_counts.num_stability_experienced_participants,
            avg_stability_experienced_participants = participant_counts.num_stability_experienced_participants / participant_counts.num_participants,
            num_build_experienced_participants = participant_counts.num_build_experienced_participants,
            avg_build_experienced_participants = participant_counts.num_build_experienced_participants / participant_counts.num_participants,
            num_test_fail_experienced_participants = participant_counts.num_test_fail_experienced_participants,
            avg_test_fail_experienced_participants = participant_counts.num_test_fail_experienced_participants / participant_counts.num_participants,
            num_compatibility_experienced_participants = participant_counts.num_compatibility_experienced_participants,
            avg_compatibility_experienced_participants = participant_counts.num_compatibility_experienced_participants / participant_counts.num_participants,
            security_adjacencys = participant_counts.security_adjacencys
        FROM participant_counts
        WHERE release_filepaths.thefilepath = participant_counts.filepath
          AND release_filepaths.release = '#{release.name}'
    EOSQL
    ActiveRecord::Base.connection.execute drop
    ActiveRecord::Base.connection.execute create
    ActiveRecord::Base.connection.execute index
    ActiveRecord::Base.connection.execute update
  end

  def populate_owners_data(release)
    drop = 'DROP TABLE IF EXISTS owners_counts'
    create = <<-EOSQL
      CREATE UNLOGGED TABLE owners_counts AS (
        SELECT filepaths.filepath, 
               COUNT(*) AS num_owners
        FROM filepaths INNER JOIN release_owners ON filepaths.filepath = release_owners.filepath
        WHERE release_owners.release = '#{release.name}'
        GROUP BY filepaths.filepath
      )
    EOSQL
    index = 'CREATE UNIQUE INDEX index_filepath_on_owners_counts ON owners_counts(filepath)'
    update = <<-EOSQL
      UPDATE release_filepaths
        SET num_owners = owners_counts.num_owners
        FROM owners_counts
        WHERE release_filepaths.thefilepath = owners_counts.filepath
          AND release_filepaths.release = '#{release.name}'
    EOSQL
    ActiveRecord::Base.connection.execute drop
    ActiveRecord::Base.connection.execute create
    ActiveRecord::Base.connection.execute index
    ActiveRecord::Base.connection.execute update
  end

  def populate_ownership_data(release)
    drop = 'DROP TABLE IF EXISTS ownership_avgs'
    
    create = <<-EOSQL
    CREATE UNLOGGED TABLE ownership_avgs AS 
      (SELECT release_owners.release orelease, release_owners.filepath AS ofilepath, 
              AVG(EXTRACT(epoch FROM (release_owners.first_ownership_date - release_owners.first_dir_commit_date))/86400) AS avg_tto, 
              AVG(release_owners.dir_commits_to_ownership) AS avg_cto, 
              AVG(EXTRACT(epoch FROM (releases.date - release_owners.first_ownership_date))/86400) AS avg_otr, 
              AVG(release_owners.dir_commits_to_release) AS avg_ctr,
              AVG(release_owners.ownership_distance) AS avg_odist
      FROM release_owners INNER JOIN releases ON release_owners.release = releases.name 
      GROUP BY orelease, ofilepath) 
    EOSQL
    
    update = <<-EOSQL
    UPDATE release_filepaths 
      SET avg_time_to_ownership = ownership_avgs.avg_tto, 
          avg_commits_to_ownership = ownership_avgs.avg_cto, 
          avg_ownership_time_to_release = ownership_avgs.avg_otr, 
          avg_owner_commits_to_release  = ownership_avgs.avg_ctr,
          avg_ownership_distance = ownership_avgs.avg_odist
      FROM ownership_avgs 
      WHERE release_filepaths.thefilepath = ownership_avgs.ofilepath AND release_filepaths.release = ownership_avgs.orelease AND release_filepaths.release = '#{release.name}'
    EOSQL
    
    ActiveRecord::Base.connection.execute drop
    ActiveRecord::Base.connection.execute create
    ActiveRecord::Base.connection.execute update
  end

  # Set these columns to zero if they are count-based
  def zero_out_the_nulls
    %w(churn
       num_owners
       num_reviews
       num_reviewers 
       num_participants
       num_security_experienced_participants
       num_bug_security_experienced_participants
       num_stability_experienced_participants
       num_build_experienced_participants
       num_test_fail_experienced_participants
       num_compatibility_experienced_participants
       security_adjacencys
       avg_sheriff_hours
       ).each do |col|
      zero_the_nulls = "UPDATE release_filepaths SET #{col}=0 WHERE #{col} IS NULL"
      ActiveRecord::Base.connection.execute zero_the_nulls
    end
  end

end
