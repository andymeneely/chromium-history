CREATE UNLOGGED TABLE developers_word_use AS (
  WITH joined AS (
    SELECT 
      t.word,
      m.*,
      date_trunc('month', m.date) AS my
    FROM technical_words t
    JOIN messages_technical_words mt ON (t.id = mt.technical_word_id)
    JOIN messages m ON (m.id = mt.message_id)
  ), messages_spoken_per_interval AS (
    SELECT 
      joined.sender_id AS dev_id,
      COUNT(DISTINCT joined.id) AS used_in,
      joined.my AS inter
    FROM joined
    GROUP BY
      dev_id, inter
  ), total_messages_per_interval AS (
    SELECT 
      COUNT(m.id) AS message_count,
      m.sender_id AS dev_id,
      date_trunc('month', m.date) AS inter
    FROM messages m
    GROUP BY 
      dev_id, inter
  ), together AS (
    SELECT 
      d.id, 
      d.email, 
      d.security_experience, 
      m.inter, 
      m.used_in AS used_in, 
      t.message_count AS total
    FROM developers d 
    JOIN messages_spoken_per_interval m 
    ON (d.id = m.dev_id)
    JOIN total_messages_per_interval t 
    ON (m.dev_id = t.dev_id) AND (m.inter = t.inter)
    WHERE security_experience <= current_date()
  ), pre AS (
    SELECT 
      id,
      AVG(CAST(used_in AS numeric)/CAST(total AS numeric)*100) AS pct_words_used_avg,
      COUNT(inter) AS intervals
    FROM together
    WHERE inter < security_experience
    GROUP BY id
  ), post AS (
    SELECT 
      id,
      AVG(CAST(used_in AS numeric)/CAST(total AS numeric)*100) AS pct_words_used_avg,
      COUNT(inter) AS intervals
    FROM together 
    WHERE inter > security_experience
    GROUP BY id
  )
  SELECT
    pr.id AS dev_id, 
    pr.pct_words_used_avg AS pre_pct_used_avg,
    pr.intervals AS pre_intervals,
    po.pct_words_used_avg AS post_pct_used_avg,
    po.intervals AS post_intervals
  FROM pre pr 
  LEFT OUTER JOIN post po 
  USING (id)
  ORDER BY id
);