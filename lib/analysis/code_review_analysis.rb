class CodeReviewAnalysis

  def populate_total_reviews_with_owner
    CodeReview.find_each do |review|
      review.update(total_reviews_with_owner: review.participants.sum(:reviews_with_owner))
    end
  end

  def populate_owner_familiarity_gap
    CodeReview.find_each do |review|
      r = review.participants
      gap = r.maximum(:reviews_with_owner) - r.minimum(:reviews_with_owner) 
      review.update(owner_familiarity_gap: gap)
    end
  end
end
