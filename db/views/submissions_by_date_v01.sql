SELECT
  event_on,
  application_type,
  COUNT(*) FILTER (WHERE event_type = 'new_version') AS submission,
  COUNT(*) FILTER (WHERE event_type = 'provider_updated') AS resubmission,
  COUNT(*) AS "total"
FROM
  all_events
WHERE
  event_type in ('new_version',  'provider_updated')
GROUP BY
  application_type,
  event_on
ORDER BY
  application_type,
  event_on
