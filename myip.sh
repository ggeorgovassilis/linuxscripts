#!/bin/sh
#
# Find the local IP by munging ipconfig output

private_ip='(127\.|172\.|10\.)'
ip_capture='(([0-9]{1,3}\.){3}[0-9]{1,3})'

# windows has ipconfig
ipconfig=`command -v ipconfig`
ifconfig=`command -v ifconfig`
ip=`command -v ip`
# windows has ipconfig but doesn't have ifconfig
if [ -n $ipconfig ] && ! [ -n $ifconfig ]
then
    ipconfig \
        | grep 'IPv4 Address' \
        | egrep -v $private_ip \
        | egrep -o $ip_pattern
# linux has ip now
elif [ -n $ip ]
then
    ip addr show \
        | grep '^\s*inet[^6]' \
        | egrep -v $private_ip \
        | egrep -o $ip_capture \
        | head -n 1
# osx still has ifconfig
elif [ -n $ifconfig ]
then
    ifconfig \
        | grep '^\s*inet[^6]' \
        | egrep -v '(127\.|172\.)' \
        | egrep -o '(([0-9]{1,3}\.){3}[0-9]{1,3})'\
        | head -n 1
else
    echo 2>&1 "Must have ipconfig or ip or ifconfig available to get IP address"
    exit 1
fi
