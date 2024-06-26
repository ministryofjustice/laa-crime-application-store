SELECT id, application_type, jsonb_array_elements(events) AS event_json
FROM application
