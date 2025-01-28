#!/bin/bash
> easycla-gerrit-v2.csv
cp easycla-gerrit-v2.sql /tmp
function cleanup {
  rm -f /tmp/easycla-gerrit-v2.sql
}
trap cleanup EXIT
if [ ! -z "$1" ]
then
  sed -i "s/{{from}}/${1}/g" /tmp/easycla-gerrit-v2.sql
else
  echo "assuming start date 2000-01-01"
  sed -i "s/{{from}}/2000-01-01/g" /tmp/easycla-gerrit-v2.sql
fi
snowsql_v3_key.sh -f easycla-gerrit-v2.sql -o output_file=easycla-gerrit-v2.csv -o quiet=true -o friendly=false -o header=true -o output_format=csv
