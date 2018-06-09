#!/bin/bash
proxy=`sh ./find-proxy.sh`

sed -i '/nordvpn/c\        server nordvpn '"$proxy"':1080' /etc/haproxy/haproxy.cfg

echo chosing proxy $proxy
service haproxy restart
