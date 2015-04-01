require 'hirb'

class NlpQueriesAnalysis

  def run

    drop = 'DROP TABLE IF EXISTS label_techmsgs_freqs'
    create = <<-EOSQL
      CREATE TABLE label_techmsgs_freqs AS (
        SELECT t.label AS label, t.word AS word, (CASE WHEN t2.freq IS NULL THEN t.freq ELSE t2.freq END) AS freq 
	FROM (
	      SELECT label, word, 0 as freq FROM labels CROSS JOIN technical_words) t 
        LEFT OUTER JOIN (
              SELECT l.label AS label, tw.word AS word, count(*) AS freq 
              FROM labels l INNER JOIN bug_labels bl ON  bl.label_id = l.label_id 
	                    INNER JOIN bugs b ON b.bug_id = bl.bug_id 
			    INNER JOIN commit_bugs cb ON cb.bug_id = b.bug_id 
			    INNER JOIN commits c ON c.commit_hash = cb.commit_hash 
			    INNER JOIN code_reviews cr ON cr.commit_hash = c.commit_hash 
			    INNER JOIN messages m ON m.code_review_id = cr.issue 
			    INNER JOIN messages_technical_words mtw ON mtw.message_id = m.id 
			    INNER JOIN technical_words tw ON tw.id = mtw.technical_word_id 
              GROUP BY l.label, tw.word) t2 ON (t.label = t2.label AND t.word = t2.word) 
        ORDER BY label, word, freq)
    EOSQL
    
    drop2 = 'DROP TABLE IF EXISTS label_techreviews_freqs'
    create2 = <<-EOSQL
      CREATE TABLE label_techreviews_freqs AS (
        SELECT t.label AS label, t.word AS word, (CASE WHEN t2.freq IS NULL THEN t.freq ELSE t2.freq END) AS freq 
	FROM (
	      SELECT label, word, 0 as freq FROM labels CROSS JOIN technical_words) t 
        LEFT OUTER JOIN (
              SELECT l.label AS label, tw.word AS word, count(*) AS freq 
              FROM labels l INNER JOIN bug_labels bl ON  bl.label_id = l.label_id 
	                    INNER JOIN bugs b ON b.bug_id = bl.bug_id 
			    INNER JOIN commit_bugs cb ON cb.bug_id = b.bug_id 
			    INNER JOIN commits c ON c.commit_hash = cb.commit_hash 
			    INNER JOIN code_reviews cr ON cr.commit_hash = c.commit_hash 
			    INNER JOIN code_reviews_technical_words cr_tw ON cr_tw.code_review_id = cr.issue 
			    INNER JOIN technical_words tw ON tw.id = cr_tw.technical_word_id 
              GROUP BY l.label, tw.word) t2 ON (t.label = t2.label AND t.word = t2.word) 
        ORDER BY label, word, freq)
    EOSQL

    Benchmark.bm(40) do |x|
      x.report("Executing drop label_techmsgs_freqs table") {ActiveRecord::Base.connection.execute drop}
      x.report("Executing create label_techmsgs_freqs table") {ActiveRecord::Base.connection.execute create}
      x.report("Executing drop label_techreviews_freqs table") {ActiveRecord::Base.connection.execute drop2}
      x.report("Executing create label_techreviews_freqs table") {ActiveRecord::Base.connection.execute create2}
    end
=begin
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
=end
  end
  
end
