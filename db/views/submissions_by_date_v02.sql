SELECT
  event_on,
  application_type,
  COUNT(*) FILTER (WHERE event_type = 'new_version' AND submission_version == 1) AS submission,
  COUNT(*) FILTER (WHERE event_type = 'new_version' AND submission_version > 1) AS resubmission,
  COUNT(*) AS "total"
FROM
  all_events
WHERE
  event_type == 'new_version'
GROUP BY
  application_type,
  event_on
ORDER BY
  application_type,
  event_on
