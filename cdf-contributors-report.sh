#!/bin/bash
rm -f cdf-contributors-report.csv 2>/dev/null
snowsql_v3_key.sh -f cdf-contributors-report.sql -o output_file=cdf-contributors-report.csv -o quiet=true -o friendly=false -o header=true -o output_format=csv
