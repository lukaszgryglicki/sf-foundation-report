#!/bin/bash
snowsql -a xmb01974.prod3.us-west-2 -u DEV_LGRYGLICKI -d ANALYTICS_DEV -s DEV_LGRYGLICKI_BRONZE_FIVETRAN_CROWD_DEV -w DBT_DEV -r DBT_TRANSFORM_DEV -o client_session_keep_alive=True --private-key-path "${HOME}/.sf/rsa_key.p8" $*
