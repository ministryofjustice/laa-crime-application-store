WITH first_submissions AS (
  SELECT DISTINCT ON (application_id)
    application_id,
    application,
    created_at AS submission_date
  FROM application_version
  WHERE pending IS FALSE
    AND (application ->> 'status')::text = 'submitted'
  ORDER BY application_id, version
)

SELECT
  first_submissions.application_id,
  application.application_type,
  (first_submissions.application ->> 'created_at')::timestamp AS draft_created_date,
  (first_submissions.application ->> 'office_code')::text AS office_code,
  first_submissions.submission_date AS submission_date,
  NULLIF(first_submissions.application ->> 'import_date', '') IS NOT NULL AS claim_imported,
  EXTRACT(
    EPOCH FROM (
      first_submissions.submission_date - (first_submissions.application ->> 'created_at')::timestamp
    )
  ) / 60 AS minutes_to_submit
FROM first_submissions
INNER JOIN application ON first_submissions.application_id = application.id
