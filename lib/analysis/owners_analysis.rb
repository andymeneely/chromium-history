require 'csv'

class OwnersAnalysis

  def populate_first_owners

    drop   = 'DROP TABLE IF EXISTS own_data'
    create = <<-EOSQL
      CREATE UNLOGGED TABLE own_data AS (
        SELECT t1.dv_id dv_id, t1.dir dir, t1.min_date min_date, c1.commit_hash sha, t1.cto cto 
        FROM (SELECT ro.dev_id dv_id, ro.directory dir, MIN(c.created_at) min_date, SUM(case when c.created_at < ro.first_ownership_date then 1 else 0 end) cto
              FROM release_owners ro INNER JOIN commits c ON c.author_id = ro.dev_id 
                                     INNER JOIN commit_filepaths cf ON cf.filepath LIKE ro.directory || '%' AND  cf.commit_hash = c.commit_hash 
              GROUP BY ro.dev_id, ro.directory) t1 INNER JOIN commits c1 ON c1.author_id = t1.dv_id AND c1.created_at = t1.min_date 
                                                   INNER JOIN commit_filepaths cf1 ON cf1.filepath LIKE t1.dir || '%' AND  cf1.commit_hash = c1.commit_hash
      )
    EOSQL

    drop2   = 'DROP TABLE IF EXISTS own_data2'
    create2 = <<-EOSQL
      CREATE UNLOGGED TABLE own_data2 AS (
        SELECT t1.dv_id dv_id, t1.dir dir, t1.min_date min_date, c1.commit_hash sha, t1.cto cto 
        FROM (SELECT ro.dev_id dv_id, ro.directory dir, MIN(c.created_at) min_date, SUM(case when c.created_at < ro.first_ownership_date then 1 else 0 end) cto 
              FROM release_owners ro INNER JOIN commits c ON c.author_id = ro.dev_id 
                                     INNER JOIN commit_filepaths cf ON cf.filepath LIKE '%' AND  cf.commit_hash = c.commit_hash 
              GROUP BY ro.dev_id, ro.directory)  t1 INNER JOIN commits c1 ON c1.author_id = t1.dv_id AND c1.created_at = t1.min_date 
                                                    INNER JOIN commit_filepaths cf1 ON cf1.filepath LIKE '%' AND  cf1.commit_hash = c1.commit_hash
      )
    EOSQL

    drop3   = 'DROP TABLE IF EXISTS own_data3'
    create3 = <<-EOSQL
      CREATE UNLOGGED TABLE own_data3 AS (
        SELECT ro.dev_id dv_id, ro.directory dir, ro.release ror, rel.date reldate, SUM(case when c.created_at < rel.date then 1 else 0 end) ctr 
        FROM release_owners ro INNER JOIN releases rel ON rel.name = ro.release 
                               INNER JOIN commits c ON c.author_id = ro.dev_id 
                               INNER JOIN commit_filepaths cf ON cf.filepath LIKE ro.directory || '%' AND  cf.commit_hash = c.commit_hash 
        GROUP BY ro.dev_id, ro.directory, ro.release, rel.date
      )
    EOSQL

    drop4   = 'DROP TABLE IF EXISTS own_data4'
    create4 = <<-EOSQL
      CREATE UNLOGGED TABLE own_data4 AS (
        SELECT ro.dev_id dv_id, ro.directory dir, ro.release ror, rel.date reldate, SUM(case when c.created_at < rel.date then 1 else 0 end) ctr 
        FROM release_owners ro INNER JOIN releases rel ON rel.name = ro.release 
                               INNER JOIN commits c ON c.author_id = ro.dev_id 
                               INNER JOIN commit_filepaths cf ON cf.filepath LIKE '%' AND  cf.commit_hash = c.commit_hash 
        GROUP BY ro.dev_id, ro.directory, ro.release, rel.date
      )
    EOSQL

    #First commit to directory date & First commit to directory hash & Commits to ownership
    update = <<-EOSQL
      UPDATE release_owners r
      SET first_dir_commit_date = own_data.min_date,
          first_dir_commit_sha = own_data.sha,
          dir_commits_to_ownership = own_data.cto
      FROM own_data
      WHERE dev_id = own_data.dv_id AND directory = own_data.dir
    EOSQL

    update2 = <<-EOSQL
      UPDATE release_owners r
      SET first_dir_commit_date = own_data2.min_date,
          first_dir_commit_sha = own_data2.sha,
          dir_commits_to_ownership = own_data2.cto
      FROM own_data2
      WHERE dev_id = own_data2.dv_id AND directory = './'
    EOSQL
    
    #Number of commits before a release
    update_commits_to_release =  <<-EOSQL
      UPDATE release_owners r 
      SET dir_commits_to_release = own_data3.ctr 
      FROM own_data3 
      WHERE r.dev_id = own_data3.dv_id AND r.directory = own_data3.dir AND r.release = own_data3.ror
    EOSQL

    update_commits_to_release2 =  <<-EOSQL
      UPDATE release_owners r 
      SET dir_commits_to_release = own_data4.ctr 
      FROM own_data4 
      WHERE directory = './' AND r.dev_id = own_data4.dv_id AND r.directory = own_data4.dir AND r.release = own_data4.ror
    EOSQL

    Benchmark.bm(40) do |x|
      x.report("Executing drop own_data table") {ActiveRecord::Base.connection.execute drop}
      x.report("Executing create own_data table") {ActiveRecord::Base.connection.execute create}
      x.report("Executing drop own_data2 table") {ActiveRecord::Base.connection.execute drop2}
      x.report("Executing create own_data2 table") {ActiveRecord::Base.connection.execute create2}
      x.report("Executing drop own_data3 table") {ActiveRecord::Base.connection.execute drop3}
      x.report("Executing create own_data3 table") {ActiveRecord::Base.connection.execute create3}
      x.report("Executing drop own_data4 table") {ActiveRecord::Base.connection.execute drop4}
      x.report("Executing create own_data4 table") {ActiveRecord::Base.connection.execute create4}
      x.report("Executing update 1st commit info, cto") {ActiveRecord::Base.connection.execute update}
      x.report("Executing update 1st commit info, cto2") {ActiveRecord::Base.connection.execute update2}
      x.report("Executing update_commits_to_release") {ActiveRecord::Base.connection.execute update_commits_to_release}
      x.report("Executing update_commits_to_release2") {ActiveRecord::Base.connection.execute update_commits_to_release2}
    end

  end
end
