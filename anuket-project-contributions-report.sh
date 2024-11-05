#!/bin/bash
rm -f anuket-project-contributions-report.csv 2>/dev/null
snowsql_v3_key.sh -f anuket-project-contributions-report.sql -o output_file=anuket-project-contributions-report.csv -o quiet=true -o friendly=false -o header=true -o output_format=csv
# snowsql_v3_key.sh -f anuket-project-contributions-report.sql > anuket-project-contributions-report.csv
