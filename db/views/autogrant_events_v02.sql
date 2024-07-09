SELECT e.id,
       e.submission_version,
       e.event_on,
       ( a.application ->> 'service_type' :: text ) AS service_key,
       Coalesce(a.application ->> 'custom_service_name',
        Coalesce(t.translation, a.application ->> 'service_type' :: text)
        ) AS service
FROM   ((all_events e
         join application_version a
           ON (( ( a.application_id = e.id )
                 AND ( a.version = e.submission_version ) )))
        left join translations t
               ON (( ( a.application ->> 'service_type' :: text ) =
                  ( t.key ) :: text ))
               AND t.translation_type = 'service')
WHERE  e.application_type = 'crm4'
       AND e.event_type = 'auto_decision'
