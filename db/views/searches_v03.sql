WITH event_types AS (
  SELECT
    id,
    jsonb_path_query_array(events, '$[*] ? (@.event_type == "assignment" || @.event_type == "unassignment" ).event_type') as assigment_arr
  FROM application
), assignments AS (
  SELECT
    app.id,
    CASE
      WHEN et.assigment_arr->>-1 = 'assignment' THEN true
      ELSE false
    END as assigned
  FROM application as app
    JOIN event_types AS et ON et.id = app.id
), defendants AS (
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
  app_ver.application ->> 'laa_reference' as laa_reference,
  app_ver.application -> 'firm_office' ->> 'name' as firm_name,
  def.client_name,
  app_ver.search_fields,
  app.has_been_assigned_to,
  app.created_at as date_submitted,
  app.updated_at as date_updated, -- events can happen in caseworker after this? should we be checking max event time as well???
  CASE WHEN app.application_state = 'submitted' AND ass.assigned THEN 'in_progress'
       WHEN app.application_state = 'submitted' AND NOT ass.assigned THEN 'not_assigned'
       ELSE app.application_state
       END AS status,
  app.application_type as submission_type,
  app.application_risk as risk
FROM application AS app
JOIN application_version AS app_ver
  ON app.id = app_ver.application_id AND app.current_version = app_ver.version
JOIN assignments AS ass
  ON ass.id = app.id
JOIN defendants AS def
    ON def.id = app.id
