#!/bin/bash
> easycla-gerrit-v2.csv
snowsql_v3_key.sh -f easycla-gerrit-v2.sql -o output_file=easycla-gerrit-v2.csv -o quiet=true -o friendly=false -o header=true -o output_format=csv
