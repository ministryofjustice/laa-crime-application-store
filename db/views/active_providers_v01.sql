with submissions as (
  select
  	application.application_type,
    application_version.application -> 'firm_office' ->> 'account_number' as office_code,
    application_version.application -> 'firm_office' ->> 'name' as firm_name,
    date_trunc('week', application_version.created_at) as submitted_start
  from application_version join application on application_version.application_id = application.id
  where version = 1 -- submission version only
  group by 1, 2, 3, 4
)

select
  application_type,
  submitted_start,
  count(distinct submissions.office_code) as office_codes_submitting_during_the_period,
  (
  	select count(distinct(subs.office_code))
	from submissions as subs
	where submissions.submitted_start >= subs.submitted_start and submissions.application_type = subs.application_type
  ) as total_office_codes_submitters,
  jsonb_agg(distinct submissions.office_code) as office_codes_during_the_period
from submissions
group by application_type, submitted_start
order by application_type, submitted_start