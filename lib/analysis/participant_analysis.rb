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

  # At the given code review, each participant may or may not have had experience in security
  def populate_security_experienced
    Participant.find_each do |participant|
      c = participant.code_review
      vuln_reviews = Participant.joins(code_review: :cvenums)\
        .where('participants.dev_id = ?  and code_reviews.created < ? ', participant.dev_id, c.created)  

      participant.update(security_experienced: vuln_reviews.any?)
    end
  end
  
  @@bug_experience_fields = [
    {:participants_field => 'stability_experienced', :code_review_field => 'stability_labeled'},
    {:participants_field => 'build_experienced', :code_review_field => 'build_labeled'},
    {:participants_field => 'test_fail_experienced', :code_review_field => 'test_fail_labeled'},
    {:participants_field => 'compatibility_experienced', :code_review_field => 'compatibility_labeled'}
  ]

  # At the given code review, each participant may or may not have had experience in bug-label related reviews. 
  def populate_bug_related_experience
    @@bug_experience_fields.each do |field|  
      Participant.find_each do |participant|
        c = participant.code_review
        reviews = Participant.joins(:code_review)\
        .where("participants.dev_id = :dev_id AND code_reviews.created < :created AND #{field[:code_review_field]} = TRUE"\
               ,{dev_id: participant.dev_id, created: c.created})  
        participant.update(field[:participants_field] => reviews.any?)
      end
    end
  end

  # At the given code review, total the number of sheriff hours that the participant has had
  def populate_sheriff_hours
    Participant.find_each do |participant|
      date = participant.code_review.created
      sheriff_hours = SheriffRotation.where("start < ? AND dev_id = ?", date, participant.dev_id).pluck(:duration)

      participant.update(sheriff_hours: sheriff_hours.inject(0, :+))
    end
  end

end#class
