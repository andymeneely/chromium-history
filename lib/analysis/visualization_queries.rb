require 'csv'

class VisualizationQueries

  def run_queries
    #comments_per_review
    cursory_review
  end
  
  def comments_per_review
    issue_com_hash = Hash.new(0)
    issue_comm_hash = CodeReview.joins(patch_sets: [{patch_set_files: :comments}]).group(:issue).count('comments.id')

    # put comment count per code review in a csv file
    CSV.open("#{Rails.configuration.datadir}/tmp/comments_per_review.csv", "w+") do |csv|
      csv << ["comment_count"]
      CodeReview.find_each do |c|
        comm_count = issue_comm_hash[c.issue]
        if comm_count == nil then comm_count = 0 end
        csv << [comm_count]
      end
    end 
  end
end
