SELECT e.id,
       e.submission_version,
       e.event_on,
       ( a.application ->> 'service_type' ) AS service_type
FROM   all_events e
       INNER JOIN application_version a
               ON a.application_id = e.id
                  AND a.version = e.submission_version
WHERE  e.application_type = 'crm4'
       AND e.event_type = 'auto_decision'
