SELECT
  a.id,
  av.version AS submission_version,
  av.created_at::date AS event_on,
  av.application ->> 'service_type' AS service_key,
  COALESCE(
    av.application ->> 'custom_service_name',
    t.translation,
    av.application ->> 'service_type'
  ) AS service
FROM application a
JOIN application_version av
  ON av.application_id = a.id
  AND av.version = a.current_version
LEFT JOIN translations t
  ON t.key = av.application ->> 'service_type'
  AND t.translation_type = 'service'
WHERE a.state = 'auto_grant'
