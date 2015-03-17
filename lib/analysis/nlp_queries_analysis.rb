require 'hirb'

class NlpQueriesAnalysis

  def run
    puts
    puts "_____Results from the nlp queries______"
    Hirb.enable

    puts "Technical words associated with too many labels: "
    puts
    puts Hirb::Helpers::AutoTable.render (TechnicalWord.joins(messages: {code_review: {commit: {commit_bugs: {bug: :labels}}}}).group("technical_words.id").order("COUNT(labels.label) DESC").limit(50).select("technical_words.id",:word,"COUNT(labels.label)"))

    #puts "Top word-bug label pairs: "
    #puts
    #puts Hirb::Helpers::AutoTable.render (TechnicalWord.joins(messages: {code_review: {commit: {commit_bugs: {bug: :labels}}}}).group("technical_words.id","labels.label").order("COUNT(*) DESC").limit(50).select(:word,"labels.label","COUNT(*)"))
	
    puts "Top technical words in reviews for commits associated to bugs"
    puts
    puts Hirb::Helpers::AutoTable.render (CodeReview.joins(messages: :technical_words).where(commit_hash: CommitBug.pluck('DISTINCT commit_hash')).group(:word).order('COUNT(code_reviews.issue) DESC').limit(50).select(:word,'COUNT(code_reviews.issue)'))
	
    puts "Top technical words in reviews for commits NOT associated to bugs"
    puts
    puts Hirb::Helpers::AutoTable.render (CodeReview.joins(messages: :technical_words).where.not(commit_hash: CommitBug.pluck('DISTINCT commit_hash')).group(:word).order('COUNT(code_reviews.issue) DESC').limit(50).select(:word,'COUNT(code_reviews.issue)'))
	
    puts "Average technical words in reviews for commits with bug associations"
    puts
    puts "#{(CodeReview.joins(messages: :technical_words).where(commit_hash: CommitBug.pluck('DISTINCT commit_hash')).pluck(:word).count).to_f/(CodeReview.where(commit_hash: CommitBug.pluck('DISTINCT commit_hash')).count)}"
	
    puts "Average technical words in reviews for commits without bugs associated"
    puts
    puts "#{(CodeReview.joins(messages: :technical_words).where.not(commit_hash: CommitBug.pluck('DISTINCT commit_hash')).pluck(:word).count).to_f/(CodeReview.where.not(commit_hash: CommitBug.pluck('DISTINCT commit_hash')).count)}"
	
    puts "Check increase of word usage over time"
	
    range0 = DateTime.parse('Tue, 5 Jan 1999 05:15:42 UTC +00:00')..Release.where(name: '5.0').pluck(:date)[0]
    range1 = Release.where(name: '5.0').pluck(:date)[0]..Release.where(name: '11.0').pluck(:date)[0]
    range2 = Release.where(name: '11.0').pluck(:date)[0]..Release.where(name: '19.0').pluck(:date)[0]
    range3 = Release.where(name: '19.0').pluck(:date)[0]..Release.where(name: '27.0').pluck(:date)[0]
    range4 = Release.where(name: '27.0').pluck(:date)[0]..Release.where(name: '35.0').pluck(:date)[0]
	
    ids = Participant.where(review_date: range0).pluck(:dev_id) + Reviewer.joins(:code_review).where(code_reviews: {created: range0}).pluck(:dev_id)
	
    old_words = Message.joins(:technical_words).where(date: range0, sender_id: ids).pluck('distinct word')
    old_usage = Message.joins(:technical_words).where(date: range0, sender_id: ids).group(:sender_id, :word).pluck(:sender_id, :word)
	
    usage1 = Message.joins(:technical_words).where(messages: {date: range1, sender_id: ids},technical_words: {word: old_words}).group(:sender_id, :word).pluck(:sender_id, :word)
    usage2 = Message.joins(:technical_words).where(messages: {date: range2, sender_id: ids},technical_words: {word: old_words}).group(:sender_id, :word).pluck(:sender_id, :word)
    usage3 = Message.joins(:technical_words).where(messages: {date: range3, sender_id: ids},technical_words: {word: old_words}).group(:sender_id, :word).pluck(:sender_id, :word)
    usage4 = Message.joins(:technical_words).where(messages: {date: range4, sender_id: ids},technical_words: {word: old_words}).group(:sender_id, :word).pluck(:sender_id, :word)
	
    puts
    puts "New dev usage of words from 5.0 in 11.0: #{(usage1 - old_usage).count}"
    puts "New dev usage of words from 5.0 in 19.0: #{(usage2 - usage1 - old_usage).count}"
    puts "New dev usage of words from 5.0 in 27.0: #{(usage3 - usage1 - usage2 - old_usage).count}"
    puts "New dev usage of words from 5.0 in 35.0: #{(usage4 - usage1 - usage2 - usage3 - old_usage).count}"
  end
  
end
