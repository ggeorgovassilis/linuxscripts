#!/bin/sh
#
# Find the local IP by munging ipconfig output

# windows has ipconfig
ipconfig=`command -v ipconfig`
ifconfig=`command -v ifconfig`
# windows has ipconfig but doesn't have ifconfig
if [ -n $ipconfig ] && ! [ -n $ifconfig ]
then
    ipconfig \
        | grep 'IPv4 Address' \
        | egrep -v '(127\.|172\.)' \
        | egrep -o '(([0-9]{1,3}\.){3}[0-9]{1,3})'
# osx and linux have ifconfig
elif [ -n $ifconfig ]
then
    ifconfig \
        | grep '^\s*inet[^6]' \
        | egrep -v '(127\.|172\.)' \
        | egrep -o '(([0-9]{1,3}\.){3}[0-9]{1,3})'\
        | head -n 1
else
    echo 2>&1 "Must have ipconfig or ifconfig available to get IP address"
    exit 1
fi
