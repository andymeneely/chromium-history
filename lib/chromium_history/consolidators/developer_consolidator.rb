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

  # Given all locations of code review particpants that we know of, make one participant table
  def consolidate_participants
    query=<<-eos
      INSERT INTO participants (dev_id, issue) 
      SELECT dev_id, issue FROM(
        SELECT owner_id as dev_id, code_review_id as issue FROM patch_sets
        UNION
        SELECT sender_id as dev_id, code_review_id as issue FROM messages WHERE sender<>'commit-bot@chromium.org'
      ) all_participants
    eos

    ActiveRecord::Base.connection.execute query

    #get the participant, and the owner
    Participant.all.find_in_batches(batch_size: 1000) do |group|
      group.each { |participant| 
        issueNumber = participant.issue
        c = CodeReview.find_by issue: issueNumber
        #owner = Developer.find_by email: c.owner_email

        #find all the code reviews where the owner is owner and one of the reviewers is participant
        #and only include reviews that were done before this one
        reviews = CodeReview.joins(:participants).where("owner_id = ? AND created < ? AND dev_id = ? ", c.owner_id, c.created, participant.dev_id)
        participant.update(reviews_with_owner: reviews.count)
      }
    end
    #if this participant and the owner have worked together before, add one to this number
  end

  def consolidate_contributors
     #Copy participants table
    query=<<-eos
      INSERT INTO contributors (dev_id, issue) 
      SELECT dev_id, issue FROM participants
    eos

    ActiveRecord::Base.connection.execute query

    # Iterate over the model with batch processing (see ActiveRecord docs) 
    Contributor.all.find_in_batches(batch_size: 1000) do |group|
      group.each { |contributor| 
        issueNumber = contributor.issue
        #take the issue number and look up in messages or comments
        mess = Message.where("code_review_id = ? AND sender_id = ?", issueNumber, contributor.dev_id)  # and sender is the contributor
        
        c = false  #default assumption is they did not contribute
        for m in mess  #we need to check all of the messages they sent to see if any of them were useful
          txt = m.text
          # this message may not be a contribution but there may be one farther down...
          if contribution?(txt)  #if this is not a contribution
            c = true
          end
        end

        #delete this row of the table once we get all done checking
        if !c
          Contributor.delete_all(["issue = ? AND dev_id = ?", issueNumber, contributor.dev_id])
        end

      }
    end
  end

  def contribution?(txt)
    txt_filtered = ''
    txt.to_s.lines { |line| 
       txt_filtered << line unless (line[0] == '>' or (line.start_with?("On ") and line.include?(" wrote:")) or (line.starts_with?("https://codereview.chromium.org/")) or (line.starts_with?("http://codereview.chromium.org/")))
#      txt_filtered << line unless (line[0] == '>'     #remove any line that starts with >
#      or (line.start_with?("On ") and line.end_with?(" wrote:"))   #remove the lines introducing the copied text
#      or (line.starts_with?("https://codereview.chromium.org/")))  #remove the links to the in line comments
    }

    if txt_filtered.length > 50
      return true
    else 
      return false
    end
  end

end

