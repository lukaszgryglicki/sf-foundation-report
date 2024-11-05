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
  a.member_display_name as member_name,
  a.github_username as identity_username,
  a.platform,
  a.member_id,
  o.organization_name,
  o.organization_id,
  count(distinct a.activity_id) as activities,
  count(distinct a.commit_id) as commits,
  count(distinct a.issue_id) as issues,
  count(distinct a.pull_request_id) as prs,
  count(distinct a.review_id) as reviews,
  date(min(a.activity_ts)) as first_activity,
  date(max(a.activity_ts)) as last_activity
from
  segments s
inner join
  analytics.silver_fact.crowd_dev_activities a
on
  s.id = a.segment_id
inner join
  analytics.bronze_fivetran_crowd_dev.organizations o
on
  a.organization_id = o.organization_id
where
  not a.member_is_bot
  and a.is_code_contribution_activity
  and o.organization_name != 'Individual - No Account'
group by
  all
order by
  activities desc
;
