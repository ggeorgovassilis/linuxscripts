#!/bin/bash
while true
do

tail -f -n 1 /var/log/syslog | \
stdbuf -o0 grep "Unknown key pressed (translated set 2, code 0x55 on isa0060/serio0)" | \
xargs -L1 bash -c 'systemctl suspend'

sleep 5
done
