SELECT
  event_on,
  COUNT(*) FILTER (WHERE event_type = 'new_version') AS submission,
  COUNT(*) FILTER (WHERE event_type = 'provider_updated') AS resubmission,
  COUNT(*) AS "total"
FROM
  all_events
WHERE
  application_type = 'crm4' AND
    event_type in ('new_version',  'provider_updated')
GROUP BY
  event_on
ORDER BY
  event_on