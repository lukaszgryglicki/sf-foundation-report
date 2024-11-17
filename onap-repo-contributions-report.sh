#!/bin/bash
rm -f onap-repo-contributions-report.csv 2>/dev/null
snowsql_v3_key.sh -f onap-repo-contributions-report.sql -o output_file=onap-repo-contributions-report.csv -o quiet=true -o friendly=false -o header=true -o output_format=csv
# snowsql_v3_key.sh -f onap-repo-contributions-report.sql > onap-repo-contributions-report.csv
