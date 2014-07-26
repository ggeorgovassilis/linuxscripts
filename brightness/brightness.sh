#!/bin/bash

user=`whoami`

if [ "$user" != "root" ]; then
    echo Re-running as root
    sudo $0 $1
    exit 0
fi

command=$1
increment=1
B=/sys/class/backlight/acpi_video1/brightness
brightness=`cat $B`

case "$command" in
	up)
		brightness=`expr $brightness + $increment`
		echo $brightness > $B
	;;
	down)
		brightness=`expr $brightness - $increment`
		echo $brightness > $B
	;;
	*)
	echo supply up or down
	;;
esac

