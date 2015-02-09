class ParticipantAnalysis 

  # At a given code review, each participant may have had prior experience with
  # the code review's owner. Count those prior experiences and update 
  # reviews_with_owner 
  def populate_reviews_with_owner
    Participant.find_each do |participant|
      cr = participant.code_review

      # Find the count of all code reviews where the owner is owner and one of
      # the reviewers is participant and only include reviews that were done
      # before this one.
      reviews = Participant\
        .where("owner_id = ? AND review_date < ? AND dev_id = ? AND dev_id <> owner_id ", \
        cr.owner_id, cr.created, participant.dev_id)

      participant.update(reviews_with_owner: reviews.count)
    end
  end#method

  # At the given code review, each participant may or may not have had 
  # experience in bug-label related reviews. 
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
  end#method

  # At the given code review, total the number of sheriff hours that the participant has had
  def populate_sheriff_hours
    Participant.find_each do |participant|
      date = participant.code_review.created
      sheriff_hours = SheriffRotation.where("start < ? AND dev_id = ?", date, \
        participant.dev_id).pluck(:duration)

      participant.update(sheriff_hours: sheriff_hours.inject(0, :+))
    end
  end#method

  # Determine the security experienced participants (SEP) who a given
  # participant has worked with before a given code review.
  def populate_security_adjacencys
    # Get all participants from security related code reviews
    all_participants = Participant.joins(:code_review)
    # all_participants = CodeReview.joins(:participants)

    Participant.find_each do |participant|
    # The code review the participant is in.
      cr = participant.code_review

      # Get all SEP counts from all prior code reviews a given participant was in.
      # sep_adj = all_participants.count(:dev_id, :conditions => ["security_experienced = true AND dev_id <> ? AND review_date < ?", participant.dev_id, cr.created])

      sep_adj = all_participants.where("created < ? AND dev_id <> ? AND security_experienced = ?", cr.created, participant.dev_id, true).count(:dev_id)

      participant.security_adjacencys = sep_adj
      participant.save
    end
  end#method
end#class