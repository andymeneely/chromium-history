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

  #
  def populate_security_adjacencys
    s_adjacencies = {} # hash

    Participant.find_each do |participant|
      c = participant.code_review

      #find all reviews where one of the reviewers is the participant and the
      # review is inspecting a vulnerability
      reviews = Participant.where( "dev_id = ? AND cvenums != 0",
        participant.dev_id)

      reviews.each do |review|
        review.security_experienced_participants.each do |adjacency|
          s_adjacencies[adjacency] += 1
        end
      end

      # Get all security_experienced participants from all code_reviews a given participant was in where they got their security_experience before the creation of the code_review

      #reviews = Participant.where("dev_id = ? AND is_inspecting_vulnerability?", participant.dev_id)

      #REVIEWS =  all reviews that a given participant is in and is looking at security vulnerabilities

      reviews = Participant.where("dev_id = ? AND NOT cvenums.empty?", participant.dev_id)

      #the NOT cvenums.empty? is also a method in the code_review class called is_inspecting_vulnerability? but i was unsure if you could call that directly

      #s_participants = all security_experienced participants from REVIEWS where they acquired their security_experience (data located in developers table) before the code_review

      s_participants = reviews.participants.where("security_experienced = ? AND ", true)

      #AND participants (developers.security_experienced < code_review.creation)

      s_participants.
    end
  end

end#class
