require 'csv'

class VisualizationQueries

  def run_queries
    comments_per_review
    cursory_sec_exp_code_rev
    max_churn_vs_total_churn
  end
  
  # get the number of comments per review
  def comments_per_review
    issue_comm_hash = Hash.new(0)
    issue_comm_hash = CodeReview.joins(patch_sets: [{patch_set_files: :comments}]).group(:issue).count('comments.id')

    CSV.open("#{Rails.configuration.datadir}/tmp/comments_per_review.csv", "w+") do |csv|
      csv << ["comment_count"]
      CodeReview.find_each do |c|
        comm_count = issue_comm_hash[c.issue]
        if comm_count == nil then comm_count = 0 end
        csv << [comm_count]
      end
    end 
  end

  # get whether or not a review is cursory and the percent security 
  # experienced participants per code review 
  def cursory_sec_exp_code_rev
    sec_exp_parts =  CodeReview.joins(:participants).where("participants.security_experienced" => true).group("code_reviews.issue").count()
    parts =  CodeReview.joins(:participants).group("code_reviews.issue").count()
    CSV.open("#{Rails.configuration.datadir}/tmp/cursory_sec_exp_review.csv", "w+") do |csv|
      csv << ["num_sec_exp","cursory"]
      CodeReview.find_each do |c|
        sec_exp_count = sec_exp_parts[c.issue]
        part_count = parts[c.issue]
        if sec_exp_count == nil then sec_exp_count = 0 end
        if parts == nil then parts = 0 end
        if parts == 0
          percent_sec_exp = 0.0
        else
          percent_sec_exp = sec_exp_count.to_f / part_count.to_f
        end
        csv << [percent_sec_exp.round(2), c.cursory]
      end
    end
  end
  
  # get the max churn and total churn per review
  def max_churn_vs_total_churn
    CSV.open("#{Rails.configuration.datadir}/tmp/max_vs_total_churn.csv", "w+") do |csv|
      csv << ["max_churn","total_churn"]
      CodeReview.find_each do |c|
      csv << [c.max_churn,c.total_churn]
      end
    end
  end
end
      
