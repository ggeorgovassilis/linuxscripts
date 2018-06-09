#!/bin/sh
proxy=`curl -s https://nordvpn.com/wp-admin/admin-ajax.php?action=servers_recommendations | jq -r ".[0].hostname"`
echo $proxy
