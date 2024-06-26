SELECT
  id,
  application_type,
  event_json, -- raw data to use when specific field is not available
  (event_json ->> 'id') as event_id,
  (event_json ->> 'submission_version')::integer as submission_version,
  (event_json ->> 'event_type') as event_type,
  (event_json ->> 'created_at')::timestamp AS event_at,
  (event_json ->> 'created_at')::timestamp::date AS event_on,
  (event_json ->> 'primary_user_id')::integer as primary_user_id,
  (event_json ->> 'secondary_user_id')::integer as secondary_user_id,
  (event_json -> 'details') as details
FROM events_raw
