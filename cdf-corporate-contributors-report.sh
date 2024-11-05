#!/bin/bash
rm -f cdf-corporate-contributors-report.csv 2>/dev/null
snowsql_v3_key.sh -f cdf-corporate-contributors-report.sql -o output_file=cdf-corporate-contributors-report.csv -o quiet=true -o friendly=false -o header=true -o output_format=csv
