with base as (
  SELECT
    application.id,
    application.application_type,
    application_version.version,
    -- get the status from the previous version for the given application id
    -- if no previous version assume it's a draft
    COALESCE(LAG(application_version.application ->> 'status', 1) OVER (
        PARTITION BY application_version.application_id
        ORDER BY version
      ), 'draft') from_status,
    -- get the status from the updated_at for the given application id
    -- if no previous version assume it's a draft
    COALESCE(LAG(application_version.application ->> 'updated_at', 1) OVER (
        PARTITION BY application_version.application_id
        ORDER BY version
      ), application_version.application ->> 'created_at')::timestamp from_time,
    application_version.application ->> 'status' as to_status,
    (application_version.application ->> 'updated_at')::timestamp as to_time
  from application_version join application on application_version.application_id = application.id
)

select
  *,
  from_time::date as from_date,
  to_time::date as to_date,
  -- extract epoch to turn an interval into a numeric
  -- guard against negative numbers (may be limited to local datasets)
  GREATEST(extract(epoch from (to_time - from_time)), 0) as processing_seconds
from base