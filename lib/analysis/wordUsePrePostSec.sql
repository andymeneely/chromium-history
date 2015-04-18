CREATE UNLOGGED TABLE developers_word_use AS (
  WITH joined AS (
    SELECT 
      t.word,
      m.*,
      date_trunc('month', m.date) AS my
    FROM technical_words t
    JOIN messages_technical_words mt ON (t.id = mt.technical_word_id)
    JOIN messages m ON (m.id = mt.message_id)
  ), code_reviews_spoken_per_interval AS (
    SELECT 
      joined.sender_id AS dev_id,
      COUNT(DISTINCT joined.code_review_id) AS used_in,
      joined.my AS inter
    FROM joined
    GROUP BY
      dev_id, inter
  ), total_code_reviews_per_interval AS (
    SELECT 
      COUNT(DISTINCT c.issue) AS code_review_count,
      p.dev_id AS dev_id,
      date_trunc('month', c.created) AS inter
    FROM code_reviews c
    JOIN participants p
    ON (p.issue = c.issue)
    GROUP BY 
      dev_id, inter
  ), together AS (
    SELECT d.id, d.email, d.security_experience, c.inter, c.used_in AS used_in, t.code_review_count AS total
    FROM developers d 
    JOIN code_reviews_spoken_per_interval c 
    ON (d.id = c.dev_id) 
    JOIN total_code_reviews_per_interval t ON (c.dev_id = t.dev_id) AND (c.inter = t.inter)
  ), pre AS (
    SELECT 
      id,
      email,
      regr_slope((CAST(used_in AS numeric)/CAST(total AS numeric))*100, 
        EXTRACT(epoch FROM inter)) AS pct_words_used_slope,
      corr((CAST(used_in AS numeric)/CAST(total AS numeric))*100, 
        EXTRACT(epoch FROM inter)) AS pct_words_used_corr,
      regr_count((CAST(used_in AS numeric)/CAST(total AS numeric))*100, 
        EXTRACT(epoch FROM inter)) AS pct_words_used_count
    FROM together
    WHERE inter < security_experience
    GROUP BY id, email
  ), post AS (
    SELECT 
      id,
      regr_slope((CAST(used_in AS numeric)/CAST(total AS numeric))*100, 
        EXTRACT(epoch FROM inter)) AS pct_words_used_slope,
      corr((CAST(used_in AS numeric)/CAST(total AS numeric))*100, 
        EXTRACT(epoch FROM inter)) AS pct_words_used_corr,
      regr_count((CAST(used_in AS numeric)/CAST(total AS numeric))*100, 
        EXTRACT(epoch FROM inter)) AS pct_words_used_count
    FROM together 
    WHERE inter > security_experience
    GROUP BY id
  )
  SELECT
    pr.id, 
    pr.email, 
    pr.pct_words_used_slope AS pre_slope,
    pr.pct_words_used_corr AS pre_corr,
    pr.pct_words_used_count AS pre_count,
    po.pct_words_used_slope AS post_slope,
    po.pct_words_used_corr AS post_corr,
    po.pct_words_used_count AS post_count
  FROM pre pr 
  JOIN post po 
  USING (id)
  ORDER BY id
);