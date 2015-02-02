class ParticipantAnalysis 

  # At a given code review, each participant may have had prior experience with the code
  # review's owner. Count those prior experiences and update reviews_with_owner 
  def populate_reviews_with_owner
    Participant.find_each do |participant|
      c = participant.code_review

      #find all the code reviews where the owner is owner and one of the reviewers is participant
      #and only include reviews that were done before this one
      reviews = Participant\
        .where("owner_id = ? AND review_date < ? AND dev_id = ? AND dev_id<>owner_id ", \
               c.owner_id, c.created, participant.dev_id)

      participant.update(reviews_with_owner: reviews.count)
    end
  end#method

  # At the given code review, each participant may or may not have had experience in bug-label related reviews. 
  def popbugulate_bug_related_experience
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

  #
  def populate_security_adjacencys
    # all code reviews that have cvenums (looking at vulnerabilities) and all the participants in it. 
    # total_participants = cvenum.joins(:code_reviews).joins(:participants)

    Participant.find_each do |participant|
      #all the security experienced participants that are not the given participant. Used with group, it returns a hash whoses keys represent dev_id and the value are the count

      #I believe this way is the more appropriate way. 
      # s_participants = total_participants.group(:dev_id).count(:dev_id, :conditions => ["security_experienced = true AND dev_id <> ?", participant.dev_id])

      #This could also be a possibility. And maybe the :group needs to go before the :condition
       # s_participants = total_participants.count(:dev_id, :conditions => ["security_experienced = true AND dev_id <> ?", participant.dev_id], :group => "dev_id")
      # from here I need to put these dev_ids and the counts into the adjacency table

      # code review the participant is in
      c = participant.code_review

      if c.is_inspecting_vulnerability?
        # i'm unsure which of the following two are correct yet
        # only security experienced participants and not the given one
        s_adjacencys_count = c.participants.group(:dev_id).count(:dev_id, :conditions => ["security_experienced = true AND dev_id <> ?", participant.dev_id])

        # the :group may need to come before :conditions to be symmantically equivalent to the statement above
        # s_adjacencys_count = c.participants.count(:dev_id, :conditions => ["security_experienced = true AND dev_id <> ?", participant.dev_id], :group => "dev_id")

        participant.security_adjacencys = s_adjacencys_count

        participant.save
      end
    end
  end

end#class
