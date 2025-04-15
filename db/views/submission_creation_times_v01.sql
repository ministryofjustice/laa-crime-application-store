with base AS (
    SELECT
    application_id,
    application.application_type,
    (app_ver.application ->> 'created_at')::timestamp AS draft_created_date,
    (app_ver.created_at)::timestamp AS submission_date,
    CASE
      WHEN (app_ver.application ->> 'import_date')::timestamp IS NOT NULL THEN true
      ELSE false
    END AS claim_imported
  FROM application_version AS app_ver
  INNER JOIN application ON app_ver.application_id = application.id
  WHERE (app_ver.application ->> 'status')::text = 'submitted'
)

SELECT *,
  EXTRACT(EPOCH FROM (submission_date - draft_created_date))/60 AS minutes_to_submit
FROM base