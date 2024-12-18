WITH defendants AS (
  SELECT
    app.id,
    CASE WHEN app.application_type = 'crm4' THEN
        (app_ver.application -> 'defendant' ->> 'first_name') || ' ' || (app_ver.application -> 'defendant' ->> 'last_name')
       ELSE
        (
          SELECT (defendants.value->>'first_name') || ' ' || (defendants.value->>'last_name')
          FROM jsonb_array_elements(app_ver.application->'defendants') AS defendants
          WHERE defendants.value->>'main' = 'true'
        )
       END AS client_name
  FROM application AS app
    JOIN application_version AS app_ver
      ON app.id = app_ver.application_id AND app.current_version = app_ver.version
)
SELECT
  app.id,
  app_ver.id as application_version_id,
  app_ver.application ->> 'ufn' as ufn,
  app_ver.application ->> 'laa_reference' as laa_reference,
  app_ver.application -> 'firm_office' ->> 'name' as firm_name,
  app_ver.application -> 'firm_office' ->> 'account_number' as account_number,
  app_ver.application ->> 'service_name' as service_name,
  app_ver.created_at as last_state_change,
  CASE app.application_risk
  WHEN 'high' THEN 3
  WHEN 'medium' THEN 2
  ELSE 1 END as risk_level,
  def.client_name,
  app_ver.search_fields,
  app.has_been_assigned_to,
  app.assigned_user_id,
  app.created_at as date_submitted,
  app.last_updated_at as last_updated, -- latest event's created_at date in most instances
  CASE WHEN app.state = 'submitted' AND app.assigned_user_id IS NOT NULL THEN 'in_progress'
       WHEN app.state = 'submitted' AND app.assigned_user_id IS NULL THEN 'not_assigned'
       ELSE app.state
       END AS status_with_assignment,
  app.application_type as application_type,
  app.application_risk as risk
FROM application AS app
JOIN application_version AS app_ver
  ON app.id = app_ver.application_id AND app.current_version = app_ver.version
JOIN defendants AS def
    ON def.id = app.id
