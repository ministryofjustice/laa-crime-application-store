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
    WHEN
      ((application ->> 'plea_category') = 'category_1a' OR (application ->> 'plea_category') = 'category_2a')
      AND (application ->> 'youth_court') = 'yes'
      THEN 1
    ELSE 0
  END AS youth_court_fee_eligible,
  created_at
  FROM   application_version
  WHERE  (application ->> 'status')::text = 'submitted'
),
decided_claims AS (
  SELECT
  CASE
    WHEN
      (application ->> 'include_youth_court_fee')::boolean IS TRUE THEN 1
    ELSE
      0
  END AS youth_court_fee_approved,
  CASE
    WHEN
      ((application ->> 'include_youth_court_fee')::boolean IS FALSE AND (application ->> 'include_youth_court_fee_original')::boolean IS TRUE) THEN 1
    ELSE
      0
  END AS youth_court_fee_rejected,
  created_at
  FROM   application_version
  WHERE  (application ->> 'status')::text IN ('granted', 'part_grant', 'rejected')
)

SELECT
  dates.day AS event_date,
  COALESCE(SUM(submitted_claims.youth_court_fee_claimed), 0) AS youth_court_fee_claimed_count,
  COALESCE(SUM(submitted_claims.youth_court_fee_eligible), 0) AS youth_court_fee_eligible_count,
  COALESCE(SUM(decided_claims.youth_court_fee_approved), 0) AS youth_court_fee_approved_count,
  COALESCE(SUM(decided_claims.youth_court_fee_rejected), 0) AS youth_court_fee_rejected_count
FROM dates
LEFT JOIN submitted_claims ON DATE(dates.day) = DATE(submitted_claims.created_at)
LEFT JOIN decided_claims ON DATE(dates.day) = DATE(decided_claims.created_at)
GROUP BY dates.day
