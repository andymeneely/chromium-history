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
  # The assumption is made of the knowledge transfer from a SEP to a non-SEP (NSEP).
  def populate_security_adjacencys
    # Get all participants from security related code reviews
    all_participants = Participant.joins(code_reviews: :cvenums)

    # In issue #184, the examples indicate that participants will gain security
    # adjacency's through non-security related code reviews.
    # With the aforementioned assumption, it seems like it would be more easily
    # accepted that a NSEP would have a greater knowledge transfer in security
    # code reviews then not. We may want to see both and see if the correlation
    # is higher for one or the other.
    # For just all code reviews, we'd want the line below.
    # all_Participants = Participant.joins(:code_reviews)

    Participant.find_each do |participant|
    # The code review the participant is in.
      cr = participant.code_review

      # Get all SEP counts from all prior code reviews a given participant was in.
      sep_adj = all_participants.count(:dev_id, :conditions => \
        ["security_experienced = true AND dev_id <> ? AND review_date < ?", \
        participant.dev_id, cr.created]).distinct

      # We don' need to group if we just want distinct, because it will be
      # grouping puts it into a hash, then getting the count of a hash gives you
      # how many times that group col showed up.
      # I think we could do .group(:dev_id). \ 
        # having("security_experienced = true AND dev_id <> ? AND review_date < ?", \
        # participant.dev_id], cr.created").size

      # Get all SEP counts from all prior code reviews a given participant was in.
      # sep_adj = all_participants.group(:dev_id).count(:dev_id, :conditions => \
        # ["security_experienced = true AND dev_id <> ? AND review_date < ?", \
        # participant.dev_id], cr.created).distinct

      participant.security_adjacencys = sep_adj
      participant.save
    end
  end#method
end#class