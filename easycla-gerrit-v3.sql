with users as (
  select distinct
    m.id as member_id,
    mi.value as username
  from
    fivetran_ingest.crowd_prod_public.memberidentities mi
  inner join
    fivetran_ingest.crowd_prod_public.members m
  on
    m.id = mi.memberid
    and mi.type = 'username'
  where
    not mi._fivetran_deleted
    and not m._fivetran_deleted
),

contributions as (
  select
    a.memberid as member_id,
    a.username,
    count(distinct a.id) as activities,
    date(min(a.timestamp)) as first_contribution,
    date(max(a.timestamp)) as last_contribution,
    listagg(distinct split_part(a.channel, '/', 3), ', ') within group (order by split_part(a.channel, '/', 3)) as gerrit_servers,
    any_value(a.url) as example_activity
  from
    fivetran_ingest.crowd_prod_public.activities a
  inner join
    users u
  on
    a.memberid = u.member_id
    and a.username = u.username
    and a.platform = 'gerrit'
  where
    a.channel ilike any ('%gerrit.onap.org%', '%gerrit.opnfv.org%', '%gerrit.o-ran-sc.org%')
    and not a._fivetran_deleted
    and a.timestamp >= '{{from}}'
  group by
    all
)

select
  member_id,
  username,
  activities,
  first_contribution,
  last_contribution,
  gerrit_servers,
  example_activity
from
  contributions
order by
  last_contribution desc,
  username asc
;
