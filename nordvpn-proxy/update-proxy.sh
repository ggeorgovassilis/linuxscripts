#!/bin/sh
# update path with whereever the script is located
cd /home/george/bin/scripts
server=`./find-proxy.sh`
echo $server
cp haproxy.template haproxy.cfg
sed -i "s/PLACEHOLDER/$server/g" haproxy.cfg
cp haproxy.cfg /etc/haproxy
service haproxy restart
