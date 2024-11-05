with project_segments as (
  select distinct
    id
  from
    fivetran_ingest.crowd_prod_public.segments
  where
    tenantid = '875c38bd-2b1b-4e91-ad07-0cfbabb4c49f'
    and parentslug = 'anuket'
    -- This has jira
    -- and id in ('2b6467a6-6d8b-4a6d-9501-cb89a5379497', '714a7151-8257-4fd1-8622-2bb5a05b67f1')
),

acts as (
  select
    a.id as activity_id,
    a.memberid as member_id,
    a.type as activity_type,
    a.platform,
    coalesce(o.displayname, '') as organization,
    coalesce(a.attributes:insertions, 0) as insertions,
    coalesce(a.attributes:deletions, 0) as deletions,
    a.attributes:state as state,
    case
        when a.type in ('pull_request-merged', 'pull_request-closed', 'pull_request-opened') then 'Pull Request'
        when a.type in ('pull_request-comment', 'pull_request-review-thread-comment', 'pull_request-reviewed') then 'Review'
        when a.type in ('patchset_approval-created') and a.attributes:"type" != 'SUBM' then 'Review'
        when a.type in ('committed-commit', 'co-authored-commit', 'authored-commit') then 'Commit'
        when a.type in ('issues-closed', 'issues-opened') and a.platform != 'jira' then 'Issue'
        when a.type in ('changeset-created', 'changeset-merged', 'changeset-abandoned', 'changeset-closed') then 'Change Set'
        when a.type in ('patchset-created', 'patchset_comment-created', 'patchset_approval-created') then 'Patch Set'
        when a.type in ('message', 'member_leave', 'member_join') then 'Groupsio'
        when a.type in ('issue-comment-created', 'issue-comment-updated') and a.platform = 'jira' then 'Jira Issue Comment'
        when a.type in ('issue-attachment-added') and a.platform = 'jira' then 'Jira Issue Attachment'
        when a.type in ('issue-created', 'issue-assigned', 'issue-updated', 'issue-closed') and a.platform = 'jira' then 'Jira Issue'
    end as activity_category,
    contains(a.sourceparentid, 'PR_') AS is_pull_request_commit,
    coalesce(a.attributes:isMainBranch::boolean, false) as is_main_branch_commit,
    case
        when activity_category != 'Commit' then null
        when is_main_branch_commit and not is_pull_request_commit then coalesce(a.sourceparentid, a.sourceid)
        else a.sourceid
    end as commit_id,
    regexp_replace(a.url, '#.*', '') as stripped_url,
    -- NOTE: also expose pr_id for review activity
    iff(activity_category in ('Pull Request', 'Review'), a.url, null) as pull_request_id,
    iff(activity_category = 'Issue', a.url, null) as issue_id,
    -- NOTE: expose issue key as jira_issue_id for Jira issues
    iff(activity_category = 'Jira Issue', a.url, null) as jira_issue_id,
    iff(activity_category = 'Review', stripped_url || memberid, null) as review_id,
    casE
        when activity_type = 'patchset-created' then sourceid
        when activity_type in ('patchset_comment-created', 'patchset_approval-created') then sourceparentid
    end as patchset_id,
    iff(activity_category = 'Change Set', sourceid, NULL) as changeset_id,
    iff(a.attributes:"reviewState" = 'APPROVED', true, false) as is_pr_approved,
  from
    project_segments s
  inner join
    fivetran_ingest.crowd_prod_public.activities a
  on
    s.id = a.segmentid
  inner join
    fivetran_ingest.crowd_prod_public.members m
  on
    a.memberid = m.id
  left join
    fivetran_ingest.crowd_prod_public.organizations o
  on
    a.organizationid = o.id
  where
    not iff(m.attributes:"isBot":"default" = 'true', true, false)
),

aggs as (
  select
    -- NOTE: stats are per member (a set of identities) and organization for which those contributions were made
    a.member_id,
    a.organization,
    count(distinct case when a.activity_category = 'Commit' then a.commit_id end) as contributed_commits,
    count(distinct case when a.activity_type in ('authored-commit', 'co-authored-commit', 'committed-commit') then a.commit_id end) as created_commits,
    sum(a.insertions) as loc_added,
    sum(a.deletions) as loc_deleted,
    sum(a.insertions + a.deletions) as loc_modified,
    count(distinct case when a.activity_category = 'Pull Request' then a.pull_request_id end) as contributed_prs,
    count(distinct case when a.activity_type = 'pull_request-opened' then a.pull_request_id end) as opened_prs,
    count(distinct case when a.activity_type = 'pull_request-closed' then a.pull_request_id end) as closed_prs,
    count(distinct case when a.activity_type = 'pull_request-closed' and a.state = 'closed' then a.pull_request_id end) as closed_unmerged_prs,
    count(distinct case when a.activity_type = 'pull_request-closed' and a.state = 'merged' then a.pull_request_id end) as closed_merged_prs,
    count(distinct case when a.activity_type = 'pull_request-merged' then a.pull_request_id end) as merged_prs,
    count(distinct case when a.activity_type = 'pull_request-reviewed' then a.pull_request_id end) as reviewed_prs,
    count(distinct case when a.activity_type = 'pull_request-reviewed' and a.is_pr_approved then a.pull_request_id end) as approved_prs,
    count(distinct case when a.activity_category = 'Review' and a.activity_type not like 'patchset%' then a.review_id end) as pr_reviews,
    count(distinct case when a.activity_category = 'Review' and a.activity_type not like 'patchset%' then a.activity_id end) as pr_review_activity,
    count(distinct case when a.activity_type = 'pull_request-comment' then a.activity_id end) as pr_comment_activity,
    count(distinct case when a.activity_type = 'patchset_approval-created' then a.activity_id end) as gerrit_approval_activity,
    count(distinct case when a.activity_type = 'patchset_approval-created' then a.changeset_id end) as gerrit_approved_changesets,
    count(distinct case when a.activity_type = 'patchset_approval-created' then a.patchset_id end) as gerrit_approved_patchsets,
    count(distinct case when a.platform = 'gerrit' then a.changeset_id end) as gerrit_active_changesets,
    count(distinct case when a.platform = 'gerrit' then a.patchset_id end) as gerrit_active_patchsets,
    count(distinct case when a.activity_type = 'changeset-merged' then a.changeset_id end) as gerrit_merged_changesets,
    count(distinct case when a.activity_type in ('patchset_comment-created', 'patchset_approval-created') then a.activity_id end) as gerrit_review_comment_activity,
    count(distinct case when a.activity_category = 'Jira Issue Comment' then a.activity_id end) as jira_issue_comment_activity,
    count(distinct case when a.activity_type = 'issue-assigned' and platform = 'jira' then a.jira_issue_id end) as jira_issues_assigned,
    count(distinct case when a.activity_type = 'issue-created' and platform = 'jira' then a.jira_issue_id end) as jira_issues_created,
    count(distinct case when a.activity_type = 'issue-closed' and platform = 'jira' then a.jira_issue_id end) as jira_issues_closed,
    count(distinct case when a.activity_type = 'issues-opened' and platform = 'github' then a.issue_id end) as github_issues_created,
    count(distinct case when a.activity_type = 'issues-closed' and platform = 'github' then a.issue_id end) as github_issues_closed,
    count(distinct case when a.activity_type = 'issue-comment' and platform = 'github' then a.activity_id end) as github_issue_comment_activity,
    count(distinct case when a.activity_type = 'comment-created' and platform = 'confluence' then a.activity_id end) as confluence_comment_activity,
    count(distinct case when a.activity_type in ('blogpost-created', 'blogpost-updated') and platform = 'confluence' then a.activity_id end) as confluence_post_activity,
    count(distinct case when a.activity_type = 'page-created' and platform = 'confluence' then a.activity_id end) as confluence_page_created_activity,
    count(distinct case when a.activity_type = 'page-updated' and platform = 'confluence' then a.activity_id end) as confluence_page_updated_activity,
    count(distinct case when a.activity_type = 'attachment-created' and platform = 'confluence' then a.activity_id end) as confluence_attachment_activity,
    count(distinct case when a.activity_type = 'message' and platform = 'groupsio' then a.activity_id end) as groupsio_message_activity,
    count(distinct case when a.activity_type = 'message' and platform = 'slack' then a.activity_id end) as slack_message_activity,
    count(distinct a.activity_id) as activities
  from
    acts a
  group by
    all
),

rep as (
  select
    d.member_id,
    m.displayname as "Display Name",
    listagg(distinct miu.value, ',') within group (order by miu.value) as "User Names",
    case
      when listagg(e.value, ',') = '' then listagg(distinct mie.value, ',') within group (order by mie.value)
      else listagg(distinct e.value, ',') within group (order by e.value)
    end as "Emails",
    d.organization as "Organization",
    -- d.contributed_commits as "Code: commits contributed to",
    d.created_commits as "Code: commits",
    d.loc_added as "Code: LOC Added",
    d.loc_modified as "Code: LOC Modified",
    d.loc_deleted as "Code: LOC Deleted",
    -- d.contributed_prs as "Github PRs: contributed to",
    d.opened_prs as "Github PRs: PRs Created",
    d.closed_prs as "Github PRs: PRs Closed",
    d.closed_unmerged_prs as "Github PRs: PRs Closed Unmerged",
    d.merged_prs as "Github PRs: PRs Merged",
    d.reviewed_prs as "Github PRs: PRs Reviewed",
    d.approved_prs as "Github PRs: PRs Approved",
    d.pr_reviews as "Github PRs: PRs Reviews",
    d.pr_review_activity as "Github PRs: PRs Review Comments",
    d.pr_comment_activity as "Github PRs: PRs Comment Activity",
    d.gerrit_approval_activity as "Gerrit: Approvals",
    -- d.gerrit_approved_changesets as "Gerrit: Approved Changesets",
    d.gerrit_approved_patchsets as "Gerrit: Approved Patchsets",
    d.gerrit_active_changesets as "Gerrit: Active Changesets",
    d.gerrit_merged_changesets as "Gerrit: Merged Changesets",
    d.gerrit_review_comment_activity as "Gerrit: Review Comments",
    d.jira_issue_comment_activity as "Jira: Comments",
    d.jira_issues_assigned as "Jira: Issues Assigned",
    d.jira_issues_created as "Jira: Issues Created",
    d.jira_issues_closed as "Jira: Issues Closed",
    d.github_issues_created as "Github Issues: Issues Created",
    -- FIXME: we don't have it
    -- d.github_issues_assigned as "Github Issues: Issues Assigned",
    d.github_issues_closed as "Github Issues: Issues Closed",
    d.github_issue_comment_activity as "Github Issues: Issue Comments",
    d.confluence_comment_activity as "Confluence: Comments",
    d.confluence_post_activity as "Confluence: Posts",
    d.confluence_page_created_activity as "Confluence: Pages Created",
    d.confluence_page_updated_activity as "Confluence: Pages Edited",
    d.confluence_attachment_activity as "Confluence: Attachments",
    d.groupsio_message_activity as "Groups.io: Messages",
    d.slack_message_activity as "Slack: Messages",
    d.activities as "All Activities"
  from
    aggs d
  left join
    fivetran_ingest.crowd_prod_public.members m
  on
    d.member_id = m.id
  left join
    lateral flatten(input => m.emails, outer => true) e
  left join
    fivetran_ingest.crowd_prod_public.memberidentities mie
  on
    d.member_id = mie.memberid
    and mie.type = 'email'
    and regexp_like(mie.value, '(.*@)(.*)')
  left join
    fivetran_ingest.crowd_prod_public.memberidentities miu
  on
    d.member_id = miu.memberid
    and miu.type = 'username'
    and not regexp_like(miu.value, '(.*@)(.*)')
  group by
    all
)

select
  r.member_id as "Member ID",
  r."Display Name",
  r."User Names",
  r."Emails",
  r."Organization",
  listagg(distinct mip.platform, ',') within group (order by mip.platform) as "Platforms",
  r."Code: commits",
  r."Code: LOC Added",
  r."Code: LOC Modified",
  r."Code: LOC Deleted",
  r."Github PRs: PRs Created",
  r."Github PRs: PRs Closed",
  r."Github PRs: PRs Closed Unmerged",
  r."Github PRs: PRs Merged",
  r."Github PRs: PRs Reviewed",
  r."Github PRs: PRs Approved",
  r."Github PRs: PRs Reviews",
  r."Github PRs: PRs Review Comments",
  r."Github PRs: PRs Comment Activity",
  r."Gerrit: Approvals",
  r."Gerrit: Approved Patchsets",
  r."Gerrit: Active Changesets",
  r."Gerrit: Merged Changesets",
  r."Gerrit: Review Comments",
  r."Jira: Comments",
  r."Jira: Issues Assigned",
  r."Jira: Issues Created",
  r."Jira: Issues Closed",
  r."Github Issues: Issues Created",
  r."Github Issues: Issues Closed",
  r."Github Issues: Issue Comments",
  r."Confluence: Comments",
  r."Confluence: Posts",
  r."Confluence: Pages Created",
  r."Confluence: Pages Edited",
  r."Confluence: Attachments",
  r."Groups.io: Messages",
  r."Slack: Messages",
  r."All Activities"
from
  rep r
left join
  fivetran_ingest.crowd_prod_public.memberidentities mip
on
  r.member_id = mip.memberid
group by
  all
order by
  r."All Activities" desc
;
