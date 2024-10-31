SELECT event_on,
       application_type,
       submission,
       resubmission,
       (submission + resubmission) AS "total"
FROM
  (SELECT event_on,
          application_type,
          COUNT(*) FILTER (
                           WHERE event_type = 'new_version'
                             AND submission_version = 1) AS submission,
          COUNT(*) FILTER (
                           WHERE (event_type = 'new_version'
                                  AND submission_version > 1
                                  AND application_type = 'crm7')
                             OR (event_type = 'provider_updated'
                                 AND application_type = 'crm4')) AS resubmission
   FROM all_events
   WHERE event_type IN ('new_version',
                        'provider_updated')
   GROUP BY application_type,
            event_on
   ORDER BY application_type,
            event_on) AS counted_values
