WITH
  base AS (
    SELECT
    application.id,
    application.application_type,
    application.created_at AS submission_date,
    (first_decision.application ->> 'status')::text AS first_decision,
    (first_decision.application ->> 'office_code')::text AS office_code,
    first_decision.decision_created_at AS first_decision_date
    FROM application
    INNER JOIN (
      SELECT application_id, application, MIN(created_at) AS decision_created_at
      FROM application_version
      GROUP BY application_id, application
    )  AS first_decision ON application.id = first_decision.application_id
    WHERE (first_decision.application ->> 'status')::text IN ('rejected', 'part_grant', 'granted')
  ),
  assignment_events AS (
    SELECT
      id,
      (events ->> 'created_at')::timestamp AS assigned_at
    FROM application
    CROSS JOIN jsonb_array_elements(caseworker_history_events) as events
    WHERE events ->> 'event_type' = 'assignment'
  )

SELECT
	base.id,
	base.application_type,
	base.submission_date,
	base.office_code,
	first_decision,
	first_decision_date,
	first_assigned_date,
	EXTRACT(EPOCH FROM (first_assigned_date - submission_date))/60 AS minutes_to_assign,
	EXTRACT(EPOCH FROM (first_decision_date - first_assigned_date))/60 AS minutes_to_assess
FROM base
INNER JOIN (
  SELECT id, MIN(assigned_at) AS first_assigned_date
  FROM assignment_events
  GROUP BY id
) AS first_assignment ON base.id = first_assignment.id
