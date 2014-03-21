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
     #Copy participants table
    query=<<-eos
      INSERT INTO contributors (email, issue) 
      SELECT email, issue FROM participants
    eos

    ActiveRecord::Base.connection.execute query

    # Iterate over the model with batch processing (see ActiveRecord docs) 
    Contributor.all.find_in_batches(batch_size: 1000) do |group|
      group.each { |contributor| 
        issueNumber = contributor.issue
        #take the issue number and look up in messages or comments
        mess = Message.where("code_review_id = ? AND sender = ?", issueNumber, contributor.email)  # and sender is the contributor
        for m in mess 
          txt = m.text
          if !contribution?(txt)  
            #delete this row of the table
            Contributor.delete_all(:issue => issueNumber, :email => contributor.email)
          end
        end
      }
    end
    ##   - delete the record if it's not a contribution
    # 
  end

  def contribution?(txt)
    if txt.length > 20
      #check for duplicates
      return true
    end
  end

end

