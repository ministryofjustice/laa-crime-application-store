-- NOTE: using lag means the subquery needs to have all the rows it returns in the lag function which is why
-- unassigned is included in the assignments subquery and then is filtered out in the join clause in the main
-- query ...
WITH dates AS (
  SELECT t.day::date as day
  FROM generate_series(timestamp '2024-06-01', current_timestamp, interval  '1 day') AS t(day)
),
application_with_cw AS (
  SELECT id,
    event_id,
    event_type,
    event_at as from_at,
    event_on as from_on,
    lag(event_at, 1, current_timestamp) OVER (PARTITION BY id ORDER BY event_at DESC) AS to_at,
    lag(event_on, 1, CURRENT_DATE + INTERVAL '1 day') OVER (PARTITION BY id ORDER BY event_at DESC) AS to_on
  FROM all_events
  WHERE application_type = 'crm4' and event_type in ('new_version', 'provider_updated', 'sent_back', 'decision')
),
assignments AS (
  SELECT id,
    event_id,
    event_type,
    event_at as assigned_at,
    lag(event_at) OVER (PARTITION BY id ORDER BY event_at DESC) AS unassigned_at
  FROM all_events
  WHERE application_type = 'crm4' and event_type in ('assignment', 'unassignment')
)

-- unassigned eod....
-- NOTE: is a application has a provider_updated event on the same day as it was sent_back this will count
-- it as assignable twice..
SELECT
  dates.day,
  count(distinct application_with_cw.event_id) as assignable,
  count(distinct assignments.event_id) as assigned
FROM dates
-- application was with the casework on the day
LEFT JOIN application_with_cw ON dates.day >= application_with_cw.from_on and dates.day < application_with_cw.to_on
  AND application_with_cw.event_type in ('new_version', 'provider_updated')
-- application was assigned after period start and before the report date and not unassigned before the report date
LEFT JOIN assignments ON assignments.assigned_at >= application_with_cw.from_at
  AND assignments.assigned_at::date <= dates.day
  AND assignments.assigned_at::date <= application_with_cw.to_at
  AND (assignments.unassigned_at IS NULL
    OR (assignments.unassigned_at::date > dates.day AND assignments.unassigned_at::date <= application_with_cw.to_at))
  AND assignments.event_type in ('assignment')
GROUP BY
  dates.day