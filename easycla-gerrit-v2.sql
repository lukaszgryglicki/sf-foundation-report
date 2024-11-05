with users as (
  select
    value as username
  from
    table(
      flatten(
        input => array_construct(
          'AlexandruAvadanii', 'BFrazer', 'ChristopherPrice', 'GaoSong', 'HWillson', 'HuabingZhao', 'InoueReo', 'Isaac.manuelraj', 'Itohan', 'IvanADAM', 'Jallolo',
          'Katel34', 'KennyPaul', 'LucProvoost', 'MagnusB', 'Manamohan', 'MattDavis', 'MehreenKaleem', 'Nagendra90287', 'PANTHEON.tech', 'Pavithra', 'Pooja03',
          'PremkumarAarna', 'Ray_NTUST', 'RehanRaza', 'SandeepAarna', 'SantoshB', 'SindhuXirasagar', 'SnehaD', 'SunilB', 'ThamlurRaju', 'TianL', 'VincentDanno',
          'YCJict', 'YatianXU', 'YoonsoonJahng', 'a.czajkowski', 'adetalhouet', 'akanshaDua', 'akapadia', 'aleemraja', 'aleksandrtaranov', 'alexeyaleynikov',
          'allison4nordix', 'alokbhatt', 'amitagh', 'andreasgeissler', 'anil1', 'ankitbhatt', 'aribeiro', 'arjunmgupta', 'atassi', 'babejmat', 'bdavis', 'bdfreeman1421',
          'bhagyalakshmi', 'bhedstrom', 'brilldav', 'brindasanthm', 'chaitanyakadiyala', 'chsailakshmi', 'codechinatelecom', 'cramstad', 'cryptomaster', 'cschowdam',
          'dacher', 'dafuse', 'daniesilamdocs', 'debbiemedina', 'demx8as6', 'deswali07', 'djhunt', 'ediaz101', 'enyinna1234', 'ezhil', 'fpaquett', 'francistoth',
          'frank123', 'fujihiro16', 'fzhang', 'ggarudapw', 'gmittal', 'gordonkoocommscope', 'gregory.hayes', 'gseiler', 'guyjacobson', 'halil.cakal', 'hujie', 'hwcm',
          'ilanap', 'jamesgu', 'jingjincs', 'jkbecker', 'jsulliva', 'kaihlavi', 'kamezawa', 'karbon', 'kavi2021', 'kbanka', 'kevin.brown1viavi', 'ktimoney', 'kwiatrox',
          'liuwenyu', 'mabelgaumkar1', 'manoj1', 'marian.vaclavik', 'mbrunner', 'mdolan', 'melliott', 'mharper', 'michal', 'mit3301', 'mizunoami123', 'nandkumar',
          'neelesh.durgapal', 'niharika.sharma', 'o-ran-sc-release', 'ojasdubey', 'onapbot', 'pau2882', 'pceicicd', 'pleigh', 'prabhjot', 'preethams', 'projitaarna',
          'rajeevme', 'rajiv.v', 'ramagp', 'rannyh', 'ranvijays', 'ravi.setti', 'ravikanth.p', 'ray.ntust', 'rgadiyar1', 'rp5811', 'rsrinivas', 'rsriraman', 'sainiashok',
          'sanchitap', 'sanjaymekhale', 'sblimkie', 'sdevaraj665', 'seshukm', 'shalomb', 'shangyuxiang', 'shaoqiu', 'sharathprakash', 'shormancorigine', 'shrek2000',
          'singh.sunil', 'singhrishipratap', 'sitedata', 'sridharkn', 'ssteve', 'subhash_singh', 'sudhakar.ndc', 'sumitc29', 'sunqiong.bri', 'surajchalapathy',
          'swaminathans', 'swapnalipode', 't.seshu', 'talig', 'talio', 'thakurveerendra', 'tperala', 'tragait', 'vamshi.nemalikonda', 'vharish', 'vikaskumar',
          'vikram.barate.gslab', 'vivemuthu', 'vmuthukrishnan', 'vvarvate', 'wangy122', 'wanyama', 'ychacon', 'yingyingwang', 'yogendrapal', 'z00245565'
        )
      )
    )
),

found_users as (
  select distinct
    m.id as member_id,
    mi.platform,
    u.username
  from
    users u
  inner join
    fivetran_ingest.crowd_prod_public.memberidentities mi
  on
    mi.type = 'username'
    and mi.platform = 'gerrit'
    and mi.value = u.username
  inner join
    fivetran_ingest.crowd_prod_public.members m
  on
    m.id = mi.memberid
  where
    not mi._fivetran_deleted
    and not m._fivetran_deleted
),

contributions as (
  select
    a.memberid as member_id,
    a.platform,
    a.username,
    a.type as activity_type,
    count(distinct a.id) as activities,
    date(min(a.timestamp)) as first_contribution,
    date(max(a.timestamp)) as last_contribution,
    listagg(distinct split_part(a.channel, '/', 3), ', ') within group (order by split_part(a.channel, '/', 3)) as gerrit_servers,
    any_value(a.url) as example_activity
  from
    fivetran_ingest.crowd_prod_public.activities a
  inner join
    found_users u
  on
    a.memberid = u.member_id
    and a.username = u.username
    and a.platform = u.platform
  where
    a.channel ilike any ('%gerrit.onap.org%', '%gerrit.opnfv.org%', '%gerrit.o-ran-sc.org%')
    and not a._fivetran_deleted
  group by
    all
),

not_found as (
  select
    null as member_id,
    null as platform,
    u.username,
    null as activity_type,
    null as activities,
    null as first_contribution,
    null as last_contribution,
    null as gerrit_servers,
    null as example_activity
  from
    users u
  left join
    found_users fu
  on
    u.username = fu.username
  where
    fu.username is null
),

report as (
  select
    member_id,
    platform,
    username,
    activity_type,
    activities,
    first_contribution,
    last_contribution,
    gerrit_servers,
    example_activity
  from
    contributions
  union select
    member_id,
    platform,
    username,
    activity_type,
    activities,
    first_contribution,
    last_contribution,
    gerrit_servers,
    example_activity
  from
    not_found
)

select
  member_id,
  platform,
  username,
  activity_type,
  activities,
  first_contribution,
  last_contribution,
  gerrit_servers,
  example_activity
from
  report
order by
  username,
  activity_type
;
