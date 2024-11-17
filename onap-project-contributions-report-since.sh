#!/bin/bash
if [ -z "${1}" ]
then
  echo "${0}: required parameter: \"yyyy-mm-dd\""
  exit 1
fi
cp onap-project-contributions-report-since.sql /tmp/
vim --not-a-term -c "%s/{{since}}/${1}/g" -c 'wq!' "/tmp/onap-project-contributions-report-since.sql"
rm -f "onap-project-contributions-report-since-${1}.csv" 2>/dev/null
snowsql_v3_key.sh -f /tmp/onap-project-contributions-report-since.sql -o output_file="onap-project-contributions-report-since-${1}.csv" -o quiet=true -o friendly=false -o header=true -o output_format=csv
