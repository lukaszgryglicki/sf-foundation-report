#!/bin/bash
> easycla-gerrit-v3.csv
cp easycla-gerrit-v3.sql /tmp
function cleanup {
  rm -f /tmp/easycla-gerrit-v3.sql
}
trap cleanup EXIT
if [ ! -z "$1" ]
then
  sed -i "s/{{from}}/${1}/g" /tmp/easycla-gerrit-v3.sql
else
  echo "assuming start date 2000-01-01"
  sed -i "s/{{from}}/2000-01-01/g" /tmp/easycla-gerrit-v3.sql
fi
snowsql_v3_key.sh -f /tmp/easycla-gerrit-v3.sql -o output_file=easycla-gerrit-v3.csv -o quiet=true -o friendly=false -o header=true -o output_format=csv
