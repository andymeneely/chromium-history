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

  def populate_cursory
    # create hashes by issue for comments and mess 
    c_issue_text_arr = CodeReview.joins(patch_sets: [{patch_set_files: :comments}]).pluck(:issue,:text)
    c_issue_text_hash = Hash[c_issue_text_arr.group_by(&:first).map{ |k,a| [k,a.map(&:last)]}]
    m_issue_text_arr = CodeReview.joins(:messages).pluck(:issue,:text)
    m_issue_text_hash = Hash[m_issue_text_arr.group_by(&:first).map{ |k,a| [k,a.map(&:last)]}]

    #put issue and if it is a cursory review in a csv
    CodeReview.find_each do |review|
      cursory_rev = false
      contrib_per_rev = 0
      c_text_arr = c_issue_text_hash[review.issue]
      m_text_arr = m_issue_text_hash[review.issue]
        
      if not c_text_arr.nil?
        c_text_arr.each do |txt|
          filtered_comm = Contributor.filter_text txt
          contrib_per_rev += filtered_comm.length
        end
      end

      if not m_text_arr.nil?
        m_text_arr.each do |txt|
          filtered_mess = Contributor.filter_text txt
          contrib_per_rev += filtered_mess.length
        end
      end
      if contrib_per_rev < 20 or review.loc_per_hour_exceeded? then cursory_rev = true end
      review.update(cursory: cursory_rev)
    end
  end

end
