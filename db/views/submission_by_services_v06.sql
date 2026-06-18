SELECT
  COALESCE((app_ver.application ->> 'service_type')::text, 'not_found') AS service_type,
  DATE_TRUNC('DAY', app_ver.created_at) date_submitted,
  COUNT(*) AS submissions
FROM application_version app_ver
JOIN application app ON app.id = app_ver.application_id
WHERE app.application_type = 'crm4' AND app_ver.version = 1 AND app_ver.pending IS FALSE
GROUP BY service_type, date_submitted;
