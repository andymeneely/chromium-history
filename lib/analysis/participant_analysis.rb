class ParticipantAnalysis 

  # At a given code review, each participant may have had prior experience with the code
  # review's owner. Count those prior experiences and update reviews_with_owner 
  def populate_reviews_with_owner
    Participant.find_each do |participant|
      issueNumber = participant.issue
      c = CodeReview.find_by issue: issueNumber

      #find all the code reviews where the owner is owner and one of the reviewers is participant
      #and only include reviews that were done before this one
      reviews = CodeReview.joins(:participants)\
        .where("owner_id = ? AND created < ? AND dev_id = ? ", c.owner_id, c.created, participant.dev_id)

      participant.update(reviews_with_owner: reviews.count)
    end

  end#method

end#class
