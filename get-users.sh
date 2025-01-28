#!/bin/bash
if [ -z "$PGPASSWORD" ]
then
  PGPASSWORD=$(cat REDSHIFT.pwd.secret)
fi
if [ -z "$PGPASSWORD" ]
then
  echo "$0: you need to specify PGPASSWORD=..."
  exit 1
fi
if [ -z "$REDSHIFTHOST" ]
then
  REDSHIFTHOST=$(cat REDSHIFT.host.secret)
fi
if [ -z "$REDSHIFTHOST" ]
then
  echo "$0: you need to specify REDSHIFTHOST=..."
  exit 2
fi
if [ -z "$REDSHIFTUSR" ]
then
  REDSHIFTUSR=$(cat REDSHIFT.usr.secret)
fi
if [ -z "$REDSHIFTUSR" ]
then
  echo "$0: you need to specify REDSHIFTUSR=..."
  exit 3
fi
if [ -z "$REDSHIFTDB" ]
then
  REDSHIFTDB=$(cat REDSHIFT.db.secret)
fi
if [ -z "$REDSHIFTDB" ]
then
  echo "$0: you need to specify REDSHIFTDB=..."
  exit 4
fi
if [ -z "$REDSHIFTPORT" ]
then
  REDSHIFTPORT=$(cat REDSHIFT.port.secret)
fi
if [ -z "$REDSHIFTPORT" ]
then
  echo "$0: you need to specify REDSHIFTPORT=..."
  exit 5
fi

if [ -z "$1" ]
then
  echo "start date not specified as a 1st argument, assuming '2000-01-01'"
  export FROM="$1"
else
  export FROM="2000-01-01"
fi
psql -h "$REDSHIFTHOST" -U "$REDSHIFTUSR" -p "$REDSHIFTPORT" "$REDSHIFTDB" -c "select distinct contributor_id, coalesce(user_name, identity_username) as username, coalesce(user_first_name || ' ' || user_last_name, identity_name) as name, coalesce(user_email, identity_email) as email from insights_contributions_view where project_id = 'a092M00001If9uZQAR' and contribution_ymd >= '${FROM}'"
