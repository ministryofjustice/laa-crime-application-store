WITH dates AS (
  SELECT t.day::DATE AS day
  FROM generate_series(timestamp '2024-12-06', current_timestamp, interval '1 day') AS t(day)
),
claims AS (
  SELECT
  CASE
    WHEN
      (application ->> 'include_youth_court_fee')::boolean IS TRUE AND
      (application ->> 'status')::text = 'submitted'
		THEN 1
    ELSE 0
  END AS youth_court_fee_claimed,
  CASE
    WHEN
      ((application ->> 'plea_category') = 'category_1a' OR (application ->> 'plea_category') = 'category_2a')
      AND (application ->> 'youth_court') = 'yes'
	  AND (application ->> 'status')::text = 'submitted'
    THEN 1
    ELSE 0
  END AS youth_court_fee_eligible,
  CASE
    WHEN
      (application ->> 'include_youth_court_fee')::boolean IS TRUE AND
      (application ->> 'status')::text IN ('granted', 'part_grant', 'rejected')
      THEN 1
    ELSE
      0
  END AS youth_court_fee_approved,
  CASE
  WHEN
    (application ->> 'include_youth_court_fee')::boolean IS FALSE AND
	  (application ->> 'include_youth_court_fee_original')::boolean IS TRUE AND
	  (application ->> 'status')::text IN ('granted', 'part_grant', 'rejected')
	THEN 1
  ELSE
    0
  END AS youth_court_fee_rejected,
  created_at
  FROM   application_version
  WHERE  (application ->> 'status')::text IN ('submitted','granted', 'part_grant', 'rejected')
)

SELECT
  dates.day AS event_date,
  COALESCE(SUM(claims.youth_court_fee_claimed), 0) AS youth_court_fee_claimed_count,
  COALESCE(SUM(claims.youth_court_fee_eligible), 0) AS youth_court_fee_eligible_count,
  COALESCE(SUM(claims.youth_court_fee_approved), 0) AS youth_court_fee_approved_count,
  COALESCE(SUM(claims.youth_court_fee_rejected), 0) AS youth_court_fee_rejected_count
FROM dates
LEFT JOIN claims ON DATE(dates.day) = DATE(claims.created_at)
GROUP BY dates.day ORDER BY event_date
