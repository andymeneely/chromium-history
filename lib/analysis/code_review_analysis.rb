class CodeReviewAnalysis

  def populate_total_reviews_with_owner
    CodeReview.find_each do |review|
      review.update(total_reviews_with_owner: review.participants.sum(:reviews_with_owner))
    end
  end

  def populate_owner_familiarity_gap
    CodeReview.find_each do |review|
      parts = review.participants
      unless parts.empty?
        gap = parts.maximum(:reviews_with_owner) - parts.minimum(:reviews_with_owner) 
        review.update(owner_familiarity_gap: gap)
      end
    end
  end

  def populate_total_sheriff_hours
    CodeReview.find_each do |review|
      review.update(total_sheriff_hours: review.participants.sum(:sheriff_hours))
    end
  end
end
