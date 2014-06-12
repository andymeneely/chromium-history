class DeveloperConsolidator

  def consolidate_reviewers
    # A beautiful query found on PostgreSQL's website: http://wiki.postgresql.org/wiki/Deleting_duplicates
    delete_duplicates=<<-eos
      DELETE FROM reviewers
        WHERE id IN (SELECT id FROM 
                          (SELECT id, row_number() 
                           OVER (PARTITION BY issue,dev_id 
                           ORDER BY id) AS rnum FROM reviewers) t
                     WHERE t.rnum > 1)
    eos
    ActiveRecord::Base.connection.execute delete_duplicates
  end

end

