class DeveloperConsolidator

  # Given all locations of code review particpants that we know of, make one participant table
  def consolidate
    consolidate_participants
    consolidate_contributors
  end

  def consolidate_participants
    query=<<-eos
      INSERT INTO participants (email, issue) 
      SELECT email, issue FROM(
        SELECT owner_email as email, code_review_id as issue FROM patch_sets
        UNION
        SELECT sender as email, code_review_id as issue FROM messages

      ) all_participants
      WHERE email!='commit-bot@chromium.org'
    eos

    ActiveRecord::Base.connection.execute query
  end

  def consolidate_contributors
    # Copy participants table
   # query=<<-eos
   #   INSERT INTO contributors (email, issue) 
   #   SELECT email, issue FROM participants
   # eos

   # ActiveRecord::Base.connection.execute query

    # Iterate over the model with batch processing (see ActiveRecord docs) 
    ##   - delete the record if it's not a contribution
    # 
  end

  def contribution?(txt)

  end

end

