SELECT
  app.id,
  app_ver.id as application_version_id,
  app_ver.search_fields,
  app.has_been_assigned_to,
  app.created_at as date_submitted,
  app.updated_at as date_updated, -- events can happen in caseworker after this? should we be checking max event time as well???
  app.application_state as status,
  app.application_type as submission_type,
  app.application_risk as risk
FROM application AS app
JOIN application_version AS app_ver on app.id = app_ver.application_id and app.current_version = app_ver.version
