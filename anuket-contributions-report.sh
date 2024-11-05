#!/bin/bash
rm -f anuket-contributions-report.csv 2>/dev/null
snowsql_v3_key.sh -f anuket-contributions-report.sql -o output_file=anuket-contributions-report.csv -o quiet=true -o friendly=false -o header=true -o output_format=csv
# snowsql_v3_key.sh -f anuket-contributions-report.sql > anuket-contributions-report.csv
