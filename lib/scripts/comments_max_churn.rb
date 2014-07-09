#!/usr/bin/env ruby
require 'csv'

issue_com_hash = Hash.new(0)
issue_comm_hash = CodeReview.joins(patch_sets: [{patch_set_files: :comments}]).group(:issue).count('comments.id')

CSV.open("/home/kd9205/chromium/history/data/churn_messages.csv", "wb") do |csv|
  CodeReview.find_each do |c|
    mc = c.max_churn
    comm_count = issue_comm_hash[c.issue]
    if comm_count == nil
      comm_count = 0
    end
    csv << [mc,comm_count]
  end
end

