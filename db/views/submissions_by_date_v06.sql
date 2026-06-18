SELECT
  av.created_at::date AS event_on,
  a.application_type,
  COUNT(*) FILTER (WHERE av.application ->> 'status' = 'submitted')     AS submission,
  COUNT(*) FILTER (WHERE av.application ->> 'status' = 'provider_updated') AS resubmission,
  COUNT(*)                                                                AS total
FROM application_version av
JOIN application a ON a.id = av.application_id
WHERE av.pending IS FALSE
  AND av.application ->> 'status' IN ('submitted', 'provider_updated')
GROUP BY a.application_type, av.created_at::date
ORDER BY a.application_type, av.created_at::date;