WITH
  base AS (
    SELECT
    application.id,
    application.application_type,
    application.created_at AS submission_date,
    application.state AS decision,
    (app_ver.application ->> 'office_code')::text AS office_code,
    (app_ver.created_at)::timestamp AS decision_date
    FROM application_version AS app_ver
    INNER JOIN application ON app_ver.application_id = application.id
    INNER JOIN (
      SELECT application_id, MAX(created_at) AS max_created_at
      FROM application_version
      GROUP BY application_id
    )  AS latest_decision ON app_ver.application_id = latest_decision.application_id
                          AND  app_ver.created_at = latest_decision.max_created_at
    WHERE (app_ver.application ->> 'status')::text IN ('rejected', 'part_grant', 'granted')
  ),
  assignment_events AS (
    SELECT
      id,
      (events ->> 'created_at')::timestamp AS assigned_at
    FROM application
    CROSS JOIN jsonb_array_elements(caseworker_history_events) as events
    WHERE events ->> 'event_type' = 'assignment'
  )

SELECT *,
  EXTRACT(EPOCH FROM (decision_date - submission_date))/60 AS minutes_to_assess
FROM base
