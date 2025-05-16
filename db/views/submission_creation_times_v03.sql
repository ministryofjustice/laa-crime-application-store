WITH
  base AS (
    SELECT DISTINCT
    app_ver.application_id,
    application.application_type,
    (app_ver.application ->> 'created_at')::timestamp AS draft_created_date,
    (app_ver.application ->> 'office_code')::text AS office_code,
    application_submissions.submission_date AS submission_date,
    CASE
      WHEN (app_ver.application ->> 'import_date')::timestamp IS NOT NULL THEN true
      ELSE false
    END AS claim_imported
  FROM application_version AS app_ver
  -- get first submitted date (so that versions made from assignments not included)
  INNER JOIN (
    SELECT
      application_id,
      MIN(created_at) AS submission_date
    FROM application_version
    WHERE (application ->> 'status')::text = 'submitted'
    GROUP BY application_id
  ) AS application_submissions ON app_ver.application_id = application_submissions.application_id
  INNER JOIN application ON app_ver.application_id = application.id
  WHERE (app_ver.application ->> 'status')::text = 'submitted'
)

SELECT *,
  EXTRACT(EPOCH FROM (submission_date - draft_created_date))/60 AS minutes_to_submit
FROM base
