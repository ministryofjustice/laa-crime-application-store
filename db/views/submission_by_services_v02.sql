SELECT
  COALESCE((app_ver.application -> 'service_type')::text, 'not_found') AS service_type,
  DATE_TRUNC('DAY', app.created_at) date_submitted
FROM application AS app
JOIN application_version AS app_ver
  ON app.id = app_ver.application_id AND app_ver.version = 1
WHERE app.application_type = 'crm4'
GROUP BY service_type, date_submitted
