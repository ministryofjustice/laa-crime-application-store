SELECT
  id,
  application_type,
  coalesce(all_events.event -> 'details' ->> 'to', 'submitted') AS status,
  (all_events.event ->> 'created_at')::timestamp AS event_at
FROM all_events
WHERE all_events.event ->> 'event_type' IN ('new_version', 'decision')
