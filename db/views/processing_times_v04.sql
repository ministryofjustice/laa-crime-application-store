WITH base AS (
  SELECT
    application.id,
    application.application_type,
    application_version.version,
    COALESCE(previous_application_version.application ->> 'status', 'draft') AS from_status,
    COALESCE(
      previous_application_version.application ->> 'updated_at',
      application_version.application ->> 'created_at'
    )::timestamp AS from_time,
    application_version.application ->> 'status' AS to_status,
    (application_version.application ->> 'updated_at')::timestamp AS to_time,
    NULLIF(application_version.application ->> 'import_date', '') IS NOT NULL AS claim_imported
  FROM application_version
  JOIN application ON application_version.application_id = application.id
  LEFT JOIN LATERAL (
    SELECT previous_application_version.application
    FROM application_version AS previous_application_version
    WHERE previous_application_version.application_id = application_version.application_id
      AND previous_application_version.pending IS FALSE
      AND previous_application_version.version < application_version.version
    ORDER BY previous_application_version.version DESC
    LIMIT 1
  ) AS previous_application_version ON TRUE
  WHERE application_version.pending IS FALSE
)

SELECT
  *,
  from_time::date AS from_date,
  to_time::date AS to_date,
  GREATEST(EXTRACT(epoch FROM (to_time - from_time)), 0) AS processing_seconds
FROM base
