SELECT id, application_type, jsonb_array_elements(events) AS event
FROM application
