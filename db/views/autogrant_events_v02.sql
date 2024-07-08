SELECT e.id,
       e.submission_version,
       e.event_on,
       ( a.application ->> 'service_type' ) AS service_key,
        CASE
          WHEN ( a.application ->> 'service_type' ) = 'custom' THEN a.application ->> 'custom_service_name'
          ELSE s.translation
        END AS service
FROM   all_events e
       INNER JOIN application_version a
               ON a.application_id = e.id
                  AND a.version = e.submission_version
       INNER JOIN service_translations s
               ON ( a.application ->> 'service_type' ) = s.key
WHERE  e.application_type = 'crm4'
       AND e.event_type = 'auto_decision'
