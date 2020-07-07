#!/bin/sh
proxy=`curl "https://nordvpn.com/wp-admin/admin-ajax.php?action=servers_recommendations&filters=\{%22country_id%22:$COUNTRY_CODE,%22servers_technologies%22:[7]\}" | jq -r '.[0].hostname'`
echo $proxy
