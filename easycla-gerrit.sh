#!/bin/bash
> easycla-gerrit.csv
snowsql_v3_key.sh -f easycla-gerrit.sql -o output_file=easycla-gerrit.csv -o quiet=true -o friendly=false -o header=true -o output_format=csv
