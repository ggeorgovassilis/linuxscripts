#!/bin/sh
cd /home/george/bin/scripts
server=`./find-proxy.sh`
cp haproxy.template haproxy.cfg
sed -i "s/PLACEHOLDER/$server/g" haproxy.cfg
cp haproxy.cfg /etc/haproxy
service haproxy restart
