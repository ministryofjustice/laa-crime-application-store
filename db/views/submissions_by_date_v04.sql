SELECT
  event_on,
  application_type,
  submission,
  resubmission,
  (submission + resubmission) AS total
FROM
  (
    SELECT
      av.created_at::date AS event_on,
      a.application_type AS application_type,
      COUNT(*) FILTER (
        WHERE
          av.application ->> 'status' = 'submitted'
      ) AS submission,
      COUNT(*) FILTER (
        WHERE
          av.application ->> 'status' = 'provider_updated'
      ) AS resubmission
    FROM
      application_version av
      LEFT JOIN application a ON a.id = av.application_id
    GROUP BY
      application_type,
      event_on
    ORDER BY
      application_type,
      event_on
  ) AS counted_values
