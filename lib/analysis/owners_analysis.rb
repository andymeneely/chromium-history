require 'csv'

class OwnersAnalysis

  def populate_first_owners
    
    #create a table with unique owners, distinct values for owners and their directories
    drop_uniq_owners_table = 'DROP TABLE IF EXISTS uniq_owners'
    create_uniq_owners_table = <<-EOSQL
      CREATE UNLOGGED TABLE uniq_owners AS (
        SELECT DISTINCT dev_id, directory, first_ownership_date FROM release_owners
      )
    EOSQL

    #create a table with first directory commit date and total commits to ownership, where directory is not src
    drop_first_commits_table = 'DROP TABLE IF EXISTS first_commits'
    create_first_commits_table = <<-EOSQL
      CREATE UNLOGGED TABLE first_commits AS (
        SELECT ro.dev_id dv_id, ro.directory dir, MIN(c.created_at) min_date, SUM(case when c.created_at < ro.first_ownership_date then 1 else 0 end) cto
        FROM uniq_owners ro INNER JOIN commits c ON c.author_id = ro.dev_id 
                            INNER JOIN commit_filepaths cf ON cf.filepath LIKE ro.directory || '%' AND  cf.commit_hash = c.commit_hash 
        GROUP BY ro.dev_id, ro.directory
      )
    EOSQL
    
    #create table to add first_commit_hashes info to first_commits, where directory is not src
    drop_first_commits_w_shas_table   = 'DROP TABLE IF EXISTS first_commits_w_shas'
    create_first_commits_w_shas_table = <<-EOSQL
      CREATE UNLOGGED TABLE first_commits_w_shas AS (
        SELECT t1.dv_id dv_id, t1.dir dir, t1.min_date min_date, c1.commit_hash sha, t1.cto cto 
        FROM first_commits t1 INNER JOIN commits c1 ON c1.author_id = t1.dv_id AND c1.created_at = t1.min_date 
                              INNER JOIN commit_filepaths cf1 ON cf1.filepath LIKE t1.dir || '%' AND  cf1.commit_hash = c1.commit_hash
      )
    EOSQL

    #create a table with first directory commit date and total commits to ownership, with directory = src
    drop_src_first_commits_table = 'DROP TABLE IF EXISTS src_first_commits'
    create_src_first_commits_table = <<-EOSQL
      CREATE UNLOGGED TABLE src_first_commits AS (
        SELECT ro.dev_id dv_id, ro.directory dir, MIN(c.created_at) min_date, SUM(case when c.created_at < ro.first_ownership_date then 1 else 0 end) cto
        FROM uniq_owners ro INNER JOIN commits c ON c.author_id = ro.dev_id AND ro.directory = './' 
                            INNER JOIN commit_filepaths cf ON cf.commit_hash = c.commit_hash 
        GROUP BY ro.dev_id, ro.directory
      )
    EOSQL
    
    #create a table to add first commit_hashes info to src_first_commits (directory = src) 
    drop_src_first_commits_w_shas_table = 'DROP TABLE IF EXISTS src_first_commits_w_shas'
    create_src_first_commits_w_shas_table = <<-EOSQL
      CREATE UNLOGGED TABLE src_first_commits_w_shas AS (
        SELECT t1.dv_id dv_id, t1.dir dir, t1.min_date min_date, c1.commit_hash sha, t1.cto cto 
        FROM src_first_commits t1 INNER JOIN commits c1 ON c1.author_id = t1.dv_id AND c1.created_at = t1.min_date 
                                  INNER JOIN commit_filepaths cf1 ON cf1.commit_hash = c1.commit_hash
      )
    EOSQL

    #create a table with unique release owners, distinct values for release, owner and their directory
    drop_uniq_rel_owners_table = 'DROP TABLE IF EXISTS uniq_rel_owners'
    create_uniq_rel_owners_table = <<-EOSQL
      CREATE UNLOGGED TABLE uniq_rel_owners AS (
        SELECT DISTINCT release, dev_id, directory FROM release_owners
      )
    EOSQL

    #create table with total commits to a directory by owners, before a release. directory is not src
    drop_commits_to_release_table  = 'DROP TABLE IF EXISTS commits_to_release'
    create_commits_to_release_table = <<-EOSQL
      CREATE UNLOGGED TABLE commits_to_release AS (
        SELECT ro.dev_id dv_id, ro.directory dir, ro.release ror, rel.date reldate, SUM(case when c.created_at < rel.date then 1 else 0 end) ctr 
        FROM uniq_rel_owners ro INNER JOIN releases rel ON rel.name = ro.release 
                                INNER JOIN commits c ON c.author_id = ro.dev_id 
                                INNER JOIN commit_filepaths cf ON cf.filepath LIKE ro.directory || '%' AND  cf.commit_hash = c.commit_hash 
        GROUP BY ro.dev_id, ro.directory, ro.release, rel.date
      )
    EOSQL

    #create table with total commits to a directory by owners, before a release. directory is src  
    drop_src_commits_to_release_table  = 'DROP TABLE IF EXISTS src_commits_to_release'
    create_src_commits_to_release_table = <<-EOSQL
      CREATE UNLOGGED TABLE src_commits_to_release AS (
        SELECT ro.dev_id dv_id, ro.directory dir, ro.release ror, rel.date reldate, SUM(case when c.created_at < rel.date then 1 else 0 end) ctr 
        FROM uniq_rel_owners ro INNER JOIN releases rel ON rel.name = ro.release AND ro.directory = './'
                                INNER JOIN commits c ON c.author_id = ro.dev_id 
                                INNER JOIN commit_filepaths cf ON cf.commit_hash = c.commit_hash 
        GROUP BY ro.dev_id, ro.directory, ro.release, rel.date
      )
    EOSQL

    #Update release_owners with 1st commit to directory date & hash + commits to ownership, directory is not src
    update_first_commit_info = <<-EOSQL
      UPDATE release_owners r
      SET first_dir_commit_date = fc.min_date,
          first_dir_commit_sha = fc.sha,
          dir_commits_to_ownership = fc.cto
      FROM first_commits_w_shas fc
      WHERE dev_id = fc.dv_id AND directory = fc.dir
    EOSQL

    #Update release_owners with 1st commit to directory date & hash + commits to ownership, directory = src
    update_src_first_commit_info = <<-EOSQL
      UPDATE release_owners r
      SET first_dir_commit_date = fc.min_date,
          first_dir_commit_sha = fc.sha,
          dir_commits_to_ownership = fc.cto
      FROM src_first_commits_w_shas fc
      WHERE dev_id = fc.dv_id AND directory = fc.dir
    EOSQL
    
    #Update the number of commits before a release, directory is not src
    update_commits_to_release =  <<-EOSQL
      UPDATE release_owners r 
      SET dir_commits_to_release = cr.ctr 
      FROM commits_to_release cr 
      WHERE r.dev_id = cr.dv_id AND r.directory = cr.dir AND r.release = cr.ror
    EOSQL

    #Update the number of commits before a release, directory is src
    update_src_commits_to_release =  <<-EOSQL
      UPDATE release_owners r
      SET dir_commits_to_release = cr.ctr 
      FROM src_commits_to_release cr 
      WHERE r.dev_id = cr.dv_id AND r.directory = cr.dir AND r.release = cr.ror
    EOSQL

    Benchmark.bm(40) do |x|
      x.report("Executing drop_uniq_owners_table") {ActiveRecord::Base.connection.execute drop_uniq_owners_table}
      x.report("Executing create_uniq_owners_table") {ActiveRecord::Base.connection.execute create_uniq_owners_table}
      x.report("Executing drop_uniq_rel_owners_table") {ActiveRecord::Base.connection.execute drop_uniq_rel_owners_table}
      x.report("Executing create_uniq_rel_owners_table") {ActiveRecord::Base.connection.execute create_uniq_rel_owners_table}

      x.report("Executing drop_1st_commits_table") {ActiveRecord::Base.connection.execute drop_first_commits_table}
      x.report("Executing create_1st_commits_table") {ActiveRecord::Base.connection.execute create_first_commits_table}
      x.report("Executing drop_1st_commits_w_shas") {ActiveRecord::Base.connection.execute drop_first_commits_w_shas_table}
      x.report("Executing create_1st_commits_w_shas") {ActiveRecord::Base.connection.execute create_first_commits_w_shas_table}

      x.report("Executing drop_src_1st_commits_table") {ActiveRecord::Base.connection.execute drop_src_first_commits_table}
      x.report("Executing create_src_1st_commits_table") {ActiveRecord::Base.connection.execute create_src_first_commits_table}
      x.report("Executing drop_src_1st_commits_w_shas") {ActiveRecord::Base.connection.execute drop_src_first_commits_w_shas_table}
      x.report("Executing create_src_1st_commits_w_shas") {ActiveRecord::Base.connection.execute create_src_first_commits_w_shas_table}

      x.report("Executing drop_commits_to_rel_table") {ActiveRecord::Base.connection.execute drop_commits_to_release_table}
      x.report("Executing create_commits_to_rel_table") {ActiveRecord::Base.connection.execute create_commits_to_release_table}

      x.report("Executing drop_src_commits_to_rel") {ActiveRecord::Base.connection.execute drop_src_commits_to_release_table}
      x.report("Executing create_src_commits_to_rel") {ActiveRecord::Base.connection.execute create_src_commits_to_release_table} 

      x.report("Executing update 1st commit info") {ActiveRecord::Base.connection.execute update_first_commit_info}
      x.report("Executing update src 1st commit info") {ActiveRecord::Base.connection.execute update_src_first_commit_info}

      x.report("Executing update_commits_to_release") {ActiveRecord::Base.connection.execute update_commits_to_release}
      x.report("Executing update_src_commits_to_release") {ActiveRecord::Base.connection.execute update_src_commits_to_release}
    end

  end
end
