-- client name
-- firm name
-- UFN
-- LAA reference

with assignments AS (
  SELECT id,
    json_agg(details ->> 'primary_user_id') as assigned_to,
  FROM all_events
  WHERE application_type = 'crm4' and event_type = 'assignment'
  group by id
),
base as (
  SELECT
    app_ver.id,
    app_ver.application_id,
    app.created_at as date_submitted,
    app.updated_at as date_updated, -- events can happen in caseworker after this? should we be checking max event time as well???
    app.state as status,
    app.application_type as submission_type,
    app.risk as risk
  FROM application AS app
  JOIN application_version AS app_ver on app.id = app_ver.application_id and app.current_version = app_ver.version
),
simple_search_fields AS (
  SELECT
    app_ver.id,
    app_ver.application_id,
    app_ver.application -> 'defendant' ->> 'first_name' || app_ver.application -> 'defendant' ->> 'last_name' as pa_client_name,
    app_ver.application ->> 'ufn' as ufn,
    app_ver.application -> 'firm_office' ->> 'name' as firm_name,
    app_ver.application ->> 'laa_reference' as laa_reference,
  FROM application AS app
  JOIN application_version AS app_ver on app.id = app_ver.application_id and app.current_version = app_ver.version
),
complex_search_fields as (
  select subq.id, subq.application_id, json_agg(defendant ->> 'first_name' || ' ' || defendant ->> 'last_name') as nsm_client_names
  from (
    select
      app_ver.id,
      app_ver.application_id,
      json_array_elements(app_ver.application -> 'defendants') as defendant
    FROM application AS app
    JOIN application_version AS app_ver on app.id = app_ver.application_id and app.current_version = app_ver.version
  ) subq
  GROUP BY subq.id, subq.application_id
)

select
  base.*,
  assignments.assigned_to,
  simple_search_fields.pa_client_name,
  simple_search_fields.ufn,
  simple_search_fields.firm_name,
  simple_search_fields.laa_reference,
  complex_search_fields.nsm_client_names
from base
join assignments on base.id = assignments.id
join simple_search_fields on base.id = simple_search_fields.id
join complex_search_fields on base.id = complex_search_fields.id
