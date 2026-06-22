WITH
  first_decision AS (
    SELECT DISTINCT ON (application_version.application_id)
      application_version.application_id,
      application_version.application,
      application_version.created_at AS first_decision_date
    FROM application_version
    WHERE
      (application_version.application ->> 'status')::text IN ('rejected', 'part_grant', 'granted')
    ORDER BY application_version.application_id, application_version.created_at
  ),
  base AS (
    SELECT
      application.id,
      application.application_type,
      application.created_at AS submission_date,
      (first_decision.application ->> 'status')::text AS first_decision,
      (first_decision.application ->> 'office_code')::text AS office_code,
      first_decision.first_decision_date
    FROM application
    INNER JOIN first_decision ON application.id = first_decision.application_id
  ),
  first_assignment AS (
    SELECT
      base.id,
      MIN((events ->> 'created_at')::timestamp) AS first_assigned_date
    FROM base
    INNER JOIN application ON application.id = base.id
    CROSS JOIN LATERAL jsonb_array_elements(application.caseworker_history_events) AS events
    WHERE events ->> 'event_type' = 'assignment'
    GROUP BY base.id
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
INNER JOIN first_assignment ON base.id = first_assignment.id
