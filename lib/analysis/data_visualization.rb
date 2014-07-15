require 'rinruby'

class DataVisualization 
  
  def initialize
    R.echo false, false
  end

  def run
    comments_per_review_hist
  end

  def comments_per_review_hist
    
    R.eval <<-EOR
      # read in data, remove outliers, create subset of data without outliers
      comment_table <- read.csv("#{Rails.configuration.datadir}/tmp/comments_per_review.csv")
      cutoff <- quantile(comment_table$comment_count, .95)
      sub_comment_table <- subset(comment_table, comment_count < cutoff)

      #Graph data and export to a png in the temp dir
      setwd("#{Rails.configuration.datadir}/tmp/")
      png(file = "comments_per_review", width = 1250, height = 1250, bg = "white")
      hist(sub_comment_table$comment_count, breaks = cutoff, probability = TRUE, col = "grey",
           main = "Comments per Code Review", xlab = "Comment Count", label = TRUE, axes = FALSE)   
      at_tick <- seq_len(cutoff)
      axis(side = 1, at = at_tick - 1, labels = FALSE)
      axis(side = 1, at = seq(1,cutoff,5) - 0.5, tick = FALSE, labels = seq(0,cutoff-1,5))
      axis(side = 2,)
      dev.off()
    EOR
  end 

  def make_scatterplot
  end
end
