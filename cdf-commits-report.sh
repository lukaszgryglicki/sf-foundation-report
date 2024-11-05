#!/bin/bash
rm -f cdf-commits-report.csv 2>/dev/null
snowsql_v3_key.sh -f cdf-commits-report.sql -o output_file=cdf-commits-report.csv -o quiet=true -o friendly=false -o header=true -o output_format=csv
