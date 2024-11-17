#!/bin/bash
rm -f onap-contributions-report.csv 2>/dev/null
snowsql_v3_key.sh -f onap-contributions-report.sql -o output_file=onap-contributions-report.csv -o quiet=true -o friendly=false -o header=true -o output_format=csv
# snowsql_v3_key.sh -f onap-contributions-report.sql > onap-contributions-report.csv
