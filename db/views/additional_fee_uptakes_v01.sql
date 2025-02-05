WITH dates AS (
  SELECT t.day::DATE AS day
  FROM generate_series(timestamp '2024-12-06', current_timestamp, interval '1 day') AS t(day)
),
submitted_claims AS (
  SELECT
  CASE
    WHEN (application ->> 'include_youth_court_fee')::boolean IS TRUE THEN 1
    ELSE 0
  END AS youth_court_fee_claimed,
  CASE
    WHEN ((application ->> 'plea_category') = 'category_1a' OR (application ->> 'plea_category') = 'category_2a') THEN 1
    ELSE 0
  END AS youth_court_fee_eligible,
  created_at
  FROM   application_version
  WHERE  (application ->> 'state')::text = 'submitted'
)

-- decided_claims AS (
--   SELECT () AS youth_court_fee_accepted,
--               created_at
--        FROM   app lication_version
--        WHERE  state IN ('granted', 'part_grant', 'rejected')
-- )

SELECT
  dates.day AS event_date,
  SUM(submitted_claims.youth_court_fee_claimed) AS youth_court_fee_claimed_count,
  SUM(submitted_claims.youth_court_fee_eligible) AS youth_court_fee_eligible_count
FROM dates
LEFT JOIN submitted_claims ON DATE(dates.day) = DATE(submitted_claims.created_at)
GROUP BY dates.day
