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
    index_uniq_owners = 'CREATE INDEX index_uniq_owners_on_dev_id ON uniq_owners(dev_id)'

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
    index_first_commits = 'CREATE INDEX index_first_commits_on_dev_id ON first_commits(dv_id)'
    
    #create table to add first_commit_hashes info to first_commits, where directory is not src
     drop_first_commits_w_shas_table   = 'DROP TABLE IF EXISTS first_commits_w_shas'
     create_first_commits_w_shas_table = <<-EOSQL
      CREATE UNLOGGED TABLE first_commits_w_shas AS (
        SELECT t1.dv_id dv_id, t1.dir dir, t1.min_date min_date, c1.commit_hash sha, t1.cto cto 
        FROM first_commits t1 INNER JOIN commits c1 ON c1.author_id = t1.dv_id AND c1.created_at = t1.min_date 
                              INNER JOIN commit_filepaths cf1 ON cf1.filepath LIKE t1.dir || '%' AND  cf1.commit_hash = c1.commit_hash
      )
    EOSQL
    index_first_commits_w_shas = 'CREATE INDEX index_first_commits_w_sha_on_dev_id ON first_commits_w_shas(dv_id)' 

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
    index_src_first_commits = 'CREATE INDEX index_src_first_commits_on_devid ON src_first_commits(dv_id)'
    
    #create a table to add first commit_hashes info to src_first_commits (directory = src) 
    drop_src_first_commits_w_shas_table = 'DROP TABLE IF EXISTS src_first_commits_w_shas'
    create_src_first_commits_w_shas_table = <<-EOSQL
      CREATE UNLOGGED TABLE src_first_commits_w_shas AS (
        SELECT t1.dv_id dv_id, t1.dir dir, t1.min_date min_date, c1.commit_hash sha, t1.cto cto 
        FROM src_first_commits t1 INNER JOIN commits c1 ON c1.author_id = t1.dv_id AND c1.created_at = t1.min_date 
                                  INNER JOIN commit_filepaths cf1 ON cf1.commit_hash = c1.commit_hash
      )
    EOSQL
    index_src_first_commits_w_shas = 'CREATE INDEX index_src_first_commits_w_shas_on_dev_id ON src_first_commits_w_shas(dv_id)'

    #create a table with unique release owners, distinct values for release, owner and their directory
    drop_uniq_rel_owners_table = 'DROP TABLE IF EXISTS uniq_rel_owners'
    create_uniq_rel_owners_table = <<-EOSQL
      CREATE UNLOGGED TABLE uniq_rel_owners AS (
        SELECT DISTINCT release, dev_id, directory FROM release_owners
      )
    EOSQL
    index_uniq_rel_owners = 'CREATE INDEX index_uniq_rel_owners_on_dev_id ON uniq_rel_owners(release,dev_id)'

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
    index_commits_to_release_table = 'CREATE INDEX index_commits_to_release_on_dev_id_release ON commits_to_release(dv_id)'

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
    index_src_commits_to_release_table = 'CREATE INDEX index_src_commits_to_release ON src_commits_to_release(dv_id)'

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

    conn = ActiveRecord::Base.connection
    Benchmark.bm(40) do |x|
      x.report("Executing drop_uniq_owners_table")   {conn.execute drop_uniq_owners_table}
      x.report("Executing create_uniq_owners_table") {conn.execute create_uniq_owners_table}
      x.report("Index on uniq_owners")               {conn.execute index_uniq_owners}

      x.report("Executing drop_uniq_rel_owners_table")   {conn.execute drop_uniq_rel_owners_table}
      x.report("Executing create_uniq_rel_owners_table") {conn.execute create_uniq_rel_owners_table}
      x.report("Index uniq_rel_owners")                  {conn.execute index_uniq_rel_owners}

      x.report("Executing drop_1st_commits_table")   {conn.execute drop_first_commits_table}
      x.report("Executing create_1st_commits_table") {conn.execute create_first_commits_table}
      x.report("Index on 1st_commits")               {conn.execute index_first_commits}

      x.report("Executing drop_1st_commits_w_shas")   {conn.execute drop_first_commits_w_shas_table}
      x.report("Executing create_1st_commits_w_shas") {conn.execute create_first_commits_w_shas_table}
      x.report("Index on 1st_commits_w_shas")         {conn.execute index_first_commits_w_shas}

      x.report("Executing drop_src_1st_commits_table")   {conn.execute drop_src_first_commits_table}
      x.report("Executing create_src_1st_commits_table") {conn.execute create_src_first_commits_table}
      x.report("Index on src_1st_commits_table")         {conn.execute index_src_first_commits}

      x.report("Executing drop_src_1st_commits_w_shas")   {conn.execute drop_src_first_commits_w_shas_table}
      x.report("Executing create_src_1st_commits_w_shas") {conn.execute create_src_first_commits_w_shas_table}
      x.report("Index on src_1st_commits_w_shas")         {conn.execute index_src_first_commits_w_shas}

      x.report("Executing drop_commits_to_rel_table")   {conn.execute drop_commits_to_release_table}
      x.report("Executing create_commits_to_rel_table") {conn.execute create_commits_to_release_table}
      x.report("Index on commit_to_rel_table")          {conn.execute index_commits_to_release_table}

      x.report("Executing drop_src_commits_to_rel")   {conn.execute drop_src_commits_to_release_table}
      x.report("Executing create_src_commits_to_rel") {conn.execute create_src_commits_to_release_table} 
      x.report("Index on src_commit_to_rel")          {conn.execute index_src_commits_to_release_table}

      x.report("Executing update 1st commit info")     {conn.execute update_first_commit_info}
      x.report("Executing update src 1st commit info") {conn.execute update_src_first_commit_info}

      x.report("Executing update_commits_to_release")     {conn.execute update_commits_to_release}
      x.report("Executing update_src_commits_to_release") {conn.execute update_src_commits_to_release}
    end

  end
end
