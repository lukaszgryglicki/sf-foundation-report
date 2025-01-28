#!/bin/bash
> easycla-gerrit.csv
cp easycla-gerrit.sql /tmp
function cleanup {
  rm -f /tmp/easycla-gerrit.sql
}
trap cleanup EXIT
if [ ! -z "$1" ]
then
  sed -i "s/{{from}}/${1}/g" /tmp/easycla-gerrit.sql
else
  echo "assuming start date 2000-01-01"
  sed -i "s/{{from}}/2000-01-01/g" /tmp/easycla-gerrit.sql
fi
snowsql_v3_key.sh -f /tmp/easycla-gerrit.sql -o output_file=easycla-gerrit.csv -o quiet=true -o friendly=false -o header=true -o output_format=csv
