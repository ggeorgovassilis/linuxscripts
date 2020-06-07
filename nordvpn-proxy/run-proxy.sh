#!/bin/sh

server=`./find-proxy.sh`
echo $server found
cp haproxy.template haproxy.cfg
sed -i "s/PLACEHOLDER/$server/g" haproxy.cfg

haproxy -db -f haproxy.cfg