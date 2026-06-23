WITH submissions AS (
  SELECT
    application.application_type,
    application_version.application -> 'office_code' AS office_code,
    date_trunc('week', application_version.created_at) AS submitted_start
  FROM application_version
  JOIN application ON application_version.application_id = application.id
  WHERE application_version.version = 1
  GROUP BY 1, 2, 3
),

weekly_submissions AS (
  SELECT
    application_type,
    submitted_start,
    count(DISTINCT office_code) AS office_codes_submitting_during_the_period,
    jsonb_agg(DISTINCT office_code) AS office_codes_during_the_period
  FROM submissions
  GROUP BY application_type, submitted_start
),

first_submission_weeks AS (
  SELECT
    application_type,
    office_code,
    min(submitted_start) AS submitted_start
  FROM submissions
  WHERE office_code IS NOT NULL
  GROUP BY application_type, office_code
),

provider_growth_by_week AS (
  SELECT
    application_type,
    submitted_start,
    count(*) AS new_office_codes
  FROM first_submission_weeks
  GROUP BY application_type, submitted_start
),

cumulative_counts AS (
  SELECT
    weekly_submissions.application_type,
    weekly_submissions.submitted_start,
    sum(COALESCE(provider_growth_by_week.new_office_codes, 0)) OVER (
      PARTITION BY weekly_submissions.application_type
      ORDER BY weekly_submissions.submitted_start
      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS total_office_codes_submitters
  FROM weekly_submissions
  LEFT JOIN provider_growth_by_week
    ON provider_growth_by_week.application_type = weekly_submissions.application_type
    AND provider_growth_by_week.submitted_start = weekly_submissions.submitted_start
)

SELECT
  weekly_submissions.application_type AS application_type,
  weekly_submissions.submitted_start AS submitted_start,
  weekly_submissions.office_codes_submitting_during_the_period AS office_codes_submitting_during_the_period,
  cumulative_counts.total_office_codes_submitters AS total_office_codes_submitters,
  weekly_submissions.office_codes_during_the_period AS office_codes_during_the_period
FROM weekly_submissions
JOIN cumulative_counts
  ON cumulative_counts.application_type = weekly_submissions.application_type
  AND cumulative_counts.submitted_start = weekly_submissions.submitted_start
ORDER BY weekly_submissions.application_type, weekly_submissions.submitted_start
