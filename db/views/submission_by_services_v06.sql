SELECT
  COALESCE((app_ver.application ->> 'service_type')::text, 'not_found') AS service_type,
  DATE_TRUNC('DAY', app.created_at) date_submitted,
  COUNT(*) AS submissions
FROM application AS app
JOIN application_version AS app_ver
  ON app_ver.application_id = app.id
WHERE app.application_type = 'crm4'
  AND app_ver.version = 1
  AND app_ver.pending IS FALSE
GROUP BY app_ver.application ->> 'service_type', DATE_TRUNC('DAY', app.created_at)
ORDER BY date_submitted, service_type;
