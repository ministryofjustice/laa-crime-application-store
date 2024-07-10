
select *, event_at - LAG(event_at) over (partition by id order by event_at asc) as event_time
from version_events
