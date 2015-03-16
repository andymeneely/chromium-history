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

  @@bug_experience_metrics = [
    {:field => 'bug_security_experience', :label => 'type-bug-security'},
    {:field => 'stability_experience', :label => 'stability-crash'},
    {:field => 'build_experience', :label => 'build'},
    {:field => 'test_fail_experience', :label => 'cr-tests-fails'},
    {:field => 'compatibility_experience', :label => 'type-compat'}
  ]
  def populate_experience_labels
    @@bug_experience_metrics.each do |metric|
      CodeReview.find_each do |review|
        any_commits = Commit.joins(commit_bugs: [bug: :labels])\
        .where('commits.commit_hash = :commit_hash AND labels.label = :label_text',\
               {commit_hash: review.commit_hash,label_text: metric[:label]}).any?
        if any_commits
          review.participants.each do |participant|
            developer = participant.developer
            if review.created < developer[metric[:field]]
              developer[metric[:field]] = review.created
              developer.save
            end
          end  
        end
      end
    end
  end

  # For each vulnerability-inspecting review, update the earliest date
  # at which the developer participated. At that date, the developer
  # is security_experienced
  def populate_experience_cve
    CodeReview.joins(:cvenums).find_each do |review|
      review.participants.each do |participant|
        developer = participant.developer
        if review.created < developer.security_experience
          developer.security_experience = review.created
          developer.save
        end
      end
    end
  end

end
