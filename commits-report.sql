with segments as (
  select distinct
    s.id
  from
    fivetran_ingest.crowd_prod_public.segments s
  inner join
    fivetran_ingest.crowd_prod_public.integrations i
  on
    s.id = i.segmentid
  where
    i.deletedat is null
    and i.tenantid = '875c38bd-2b1b-4e91-ad07-0cfbabb4c49f'
    and s.grandparentslug = 'project-jupyter'
)
select
  count(distinct a.commit_id) as commits
from
  segments s
inner join
  analytics.silver_fact.crowd_dev_activities a
on
  s.id = a.segment_id
where
  not a.member_is_bot
  and a.is_code_contribution_activity
;
