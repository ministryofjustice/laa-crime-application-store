SELECT
  a.id,
  av.version AS submission_version,
  av.created_at::date AS event_on,
  av.application ->> 'service_type' :: text AS service_key,
  COALESCE(
    av.application ->> 'custom_service_name',
    COALESCE(
      t.translation, av.application ->> 'service_type' :: text
    )
  ) AS service
FROM
  application_version av
  INNER JOIN application a ON a.id = av.application_id
  AND a.current_version = av.version
  LEFT JOIN translations t ON t.key :: text = av.application ->> 'service_type' :: text
  AND t.translation_type = 'service'
WHERE
  a.state = 'auto_grant'
