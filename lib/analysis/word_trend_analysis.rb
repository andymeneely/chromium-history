class WordTrendAnalysis
  def populate
    PsqlUtil.execute "CREATE TABLE IF NOT EXISTS word_trends (slope numeric, corr numeric, count numeric, word varchar);"

    sql = <<-EOSQL
        WITH joined AS (
          SELECT 
            t.word,
            m.*,
            date_trunc('month', m.date) AS my
          FROM 
            technical_words t
              JOIN messages_technical_words mt ON (t.id = mt.technical_word_id)
              JOIN messages m ON (m.id = mt.message_id)
        ), devs AS (
          SELECT 
            COUNT(DISTINCT joined.sender_id) used,
            joined.word AS word,
            joined.my AS date_used
          FROM 
            joined
          GROUP BY
            word, date_used
        ), month_interval AS (
          SELECT
            COUNT(DISTINCT sender_id) AS total_dev,
            COUNT(id) AS total_mess,
            date_trunc('month', date) AS my
          FROM 
            messages
          GROUP BY my
        ), word_trend AS (
          SELECT
            regr_slope( (CAST(devs.used AS numeric)/CAST(month_interval.total_dev AS numeric))*100, 
                        EXTRACT(epoch FROM devs.date_used)) AS slope,
            corr(       (CAST(devs.used AS numeric)/CAST(month_interval.total_dev AS numeric))*100, 
                        EXTRACT(epoch FROM devs.date_used)) AS cor,
            regr_count( (CAST(devs.used AS numeric)/CAST(month_interval.total_dev AS numeric))*100, 
                        EXTRACT(epoch FROM devs.date_used)) AS count,
            devs.word
          FROM 
            devs INNER JOIN month_interval ON devs.date_used = month_interval.my
          GROUP BY devs.word
        )
        INSERT INTO word_trends
        (SELECT * FROM word_trend
          WHERE word_trend.slope IS NOT NULL
          AND ABS(word_trend.cor) BETWEEN 0.7 AND 0.99);
      EOSQL
    PsqlUtil.execute sql
  end

  def pre_vs_post_sec_exp
    PsqlUtil.execute_file Rails.root.join 'lib', 'analysis', 'wordUsePrePostSec.sql'
  end
end
