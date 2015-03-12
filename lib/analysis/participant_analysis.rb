class ParticipantAnalysis 
  
  def populate_adjacency_list
    insert=<<-EOSQL
      INSERT INTO adjacency_list(dev1_id, dev2_id, issue, review_date)
        SELECT p1.dev_id, p2.dev_id, p1.issue, p1.review_date
        FROM participants p1 INNER JOIN participants p2 
             ON ( p1.issue = p2.issue
                  AND p1.dev_id < p2.dev_id )
    EOSQL
    index = 'CREATE INDEX index_adjacency_list_on_dev_ids ON adjacency_list(dev1_id, dev2_id)'
    ActiveRecord::Base.connection.execute insert
    ActiveRecord::Base.connection.execute index
  end

  # At the given code review, each participant may or may not have had experience in bug-label related reviews. 
  def populate_bug_related_experience
    update=<<-eos
    UPDATE participants 
    SET security_experienced = (developers.security_experience < participants.review_date), 
        bug_security_experienced = (developers.bug_security_experience < participants.review_date), 
        stability_experienced = (developers.stability_experience < participants.review_date), 
        build_experienced = (developers.build_experience < participants.review_date),
        test_fail_experienced = (developers.test_fail_experience < participants.review_date),
        compatibility_experienced = (developers.compatibility_experience < participants.review_date)
    FROM developers WHERE developers.id = participants.dev_id;
    eos
    ActiveRecord::Base.connection.execute update
  end

  # At the given code review, total the number of sheriff hours that the participant has had
  def populate_sheriff_hours
    Participant.find_each do |participant|
      date = participant.code_review.created
      sheriff_hours = SheriffRotation.where("start < ? AND dev_id = ?", date, participant.dev_id).pluck(:duration)

      participant.update(sheriff_hours: sheriff_hours.inject(0, :+))
    end
  end

  # Determine the number of security experienced participants (SEP) who a given
  # participant has worked with before a given code review.
  def populate_security_adjacencys
    #Participant.find_each do |participant|
    #  # Get all SEP counts from all prior code reviews a given participant was in.
    #  # sep_adj = all_participants.count(:dev_id, :conditions => ["security_experienced = true AND dev_id <> ? AND review_date < ?", participant.dev_id, cr.created])
    #  query = Participant.where("review_date < ? AND dev_id <> ? AND security_experienced = ?", participant.review_date, participant.dev_id, true)
    #  sep_adj = query.count(:dev_id)
    #  participant.security_adjacencys = sep_adj
    #  participant.save
    #end
  end#method
  
  # At a given code review, each participant may have had prior experience with the code
  # review's owner. Count those prior experiences and update reviews_with_owner 
  def populate_reviews_with_owner
    drop = 'DROP TABLE IF EXISTS reviews_with_owner_counts'
    # Give me the participations where 
    #  (a) the owner and participant participated together 
    #  (b) the review happened in the past
    #  ...then count those and aggregated it for each participant entry
    create = <<-EOSQL
      CREATE UNLOGGED TABLE reviews_with_owner_counts AS (
        SELECT p_owner.id, 
               COUNT(*) AS reviews_with_owner
        FROM participants p_owner INNER JOIN adjacency_list al
          ON ( ( (p_owner.owner_id = al.dev1_id AND p_owner.dev_id = al.dev2_id)
                  OR 
                 (p_owner.owner_id = al.dev2_id AND p_owner.dev_id = al.dev1_id)
               )
               AND al.review_date < p_owner.review_date
             )
        GROUP BY p_owner.id
      )
    EOSQL
    index = 'CREATE UNIQUE INDEX index_reviews_with_owner_count_on_id ON reviews_with_owner_counts(id)'
    update = <<-EOSQL
      UPDATE participants
      SET reviews_with_owner = reviews_with_owner_counts.reviews_with_owner
      FROM reviews_with_owner_counts
      WHERE participants.id = reviews_with_owner_counts.id
    EOSQL
    ActiveRecord::Base.connection.execute drop
    ActiveRecord::Base.connection.execute create
    ActiveRecord::Base.connection.execute index
    ActiveRecord::Base.connection.execute update
  end#method

end#class
