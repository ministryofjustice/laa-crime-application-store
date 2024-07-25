with base as (
	SELECT
	  application.application_type as submission_type,
		application_version.version,
		COALESCE(LAG(application_version.application ->> 'status', 1) OVER (
	  	  PARTITION BY application_version.application_id
	      ORDER BY version
	    ), 'draft') from_status,
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
	GREATEST(extract(epoch from (to_time - from_time)), 0) as processing_seconds
from base