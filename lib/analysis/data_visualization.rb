require 'rinruby'

# Sites that I found useful for making these graphs:
#   A introduction to R, good if you're just starting or for ctrl-f searching
#     - http://cran.r-project.org/doc/manuals/r-release/R-intro.html
#   Gives you the basics for making graphs useful to us, look through the sidebar
#   - http://www.statmethods.net/graphs/creating.html
#   For the finer parts of creating axis
#   - http://stat.ethz.ch/R-manual/R-patched/library/graphics/html/axis.html
#   What you can do when creating png files (a lot of this library is useful)
#   - http://stat.ethz.ch/R-manual/R-devel/library/grDevices/html/png.html
#
#   Note for testing: if doing this in the development env you will need to add
#   #{Dir.getwd} before the rails config call in the read csv functions

class DataVisualization 
  
  def initialize
    R.echo false, false
  end

  def run
    # setwd so that graphs are dumped in the tmp dir
    R.eval <<-EOR
      setwd("#{Rails.configuration.datadir}/tmp/")
    EOR
    comments_per_review_hist
    cursory_vs_sec_exp_review_box
    max_vs_total_churn_hex_scatter
    max_vs_total_churn_pdf_scatter
  end

  def comments_per_review_hist
    R.eval <<-EOR
      # read in data, remove outliers, create subset of data without outliers
      comment_table <- read.csv("#{Rails.configuration.datadir}/tmp/comments_per_review.csv")
      cutoff <- quantile(comment_table$comment_count, .95)
      sub_comment_table <- subset(comment_table, comment_count < cutoff)

      #Graph data and export to a png in the tmp dir
      png(file = "comments_per_review.png", width = 1250, height = 1250, bg = "white")
      hist(sub_comment_table$comment_count, breaks = cutoff, probability = TRUE, col = "grey",
           main = "Comments per Code Review", xlab = "Comment Count", label = TRUE, axes = FALSE)   
      at_tick <- seq_len(cutoff)
      
      #label the axis for a clearer graph
      axis(side = 1, at = at_tick - 1, labels = FALSE)
      axis(side = 1, at = seq(1,cutoff,5) - 0.5, tick = FALSE, labels = seq(0,cutoff-1,5))
      axis(side = 2,)
      dev.off()
    EOR
  end 

  def cursory_vs_sec_exp_review_box
    R.eval <<-EOR
      # read in data and store columns in variables
      curs_vuln_table <- read.csv("#{Rails.configuration.datadir}/tmp/cursory_sec_exp_review.csv")
      x <- curs_vuln_table$cursory
      y <- curs_vuln_table$num_sec_exp

      #Graph data, export as a png 
      png(file = "cursory_vs_sec_exp_rev.png", width = 1500, height = 1500, bg = "white")
      plot(x,y, main="Cursory Reviews vs Security Experience per Code Review", xlab = "Cursory",
           ylab = "% Security Experienced")
      dev.off()
    EOR
  end

  def max_vs_total_churn_hex_scatter
    R.eval <<-EOR
    #read data in and put into bins (from the hexbin library)
    churn_table <- read.csv("#{Rails.configuration.datadir}/tmp/max_vs_total_churn.csv")
    library(hexbin)
    bin<-hexbin(churn_table$max_churn, churn_table$total_churn, xbins=50) 

    #Graph data, export as png
    png(file = "max_vs_total_churn.png", width = 1500, height = 1500, bg = "white")
    plot(bin, main="Max Churn vs Total Churn per Code Review", xlab = "Max Churn",
           ylab = "Total Churn")
    dev.off()
    EOR
  end

  def max_vs_total_churn_pdf_scatter
    R.eval <<-EOR
    #read in data and store in coulmns in variables
    churn_table <- read.csv("#{Rails.configuration.datadir}/tmp/max_vs_total_churn.csv")
    x <- churn_table$max_churn
    y <- churn_table$total_churn

    #Graph data, export as png
    pdf(file = "max_vs_total_churn.pdf")
    plot(x,y, main="Max Churn vs Total Churn per Code Review", xlab = "Max Churn",
           ylab = "Total Churn", col=rgb(0,100,0,50,maxColorValue=255), pch=16)
    dev.off()
    EOR
  end

end
