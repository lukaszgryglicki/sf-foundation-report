#!/bin/bash
rm -f contributing-organizations.csv 2>/dev/null
snowsql_v3_key.sh -f contributing-organizations.sql -o output_file=contributing-organizations.csv -o quiet=true -o friendly=false -o header=true -o output_format=csv
