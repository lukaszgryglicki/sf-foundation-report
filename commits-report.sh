#!/bin/bash
rm -f commits-report.csv 2>/dev/null
snowsql_v3_key.sh -f commits-report.sql -o output_file=commits-report.csv -o quiet=true -o friendly=false -o header=true -o output_format=csv
