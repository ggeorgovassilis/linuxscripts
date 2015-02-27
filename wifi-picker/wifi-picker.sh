#!/bin/bash
wlan=$1
SSID=$2

TMP=/tmp/wlanlist

iwlist $wlan scan > $TMP || exit 2
out=`tac $TMP | grep "$SSID\|Quality\|Address" | sed -n 's/.*ESSID\:\"\(.*\)\"\|.*Quality=\([0-9][0-9]\).*\|.*Address\: \(.*\)/\1\2\3/p'`

SHOW_NEXT_LINE=-1
BSSID=""
QUALITY=0
rm -f $TMP 2> /dev/null
for LINE in ${out} ; do
	case $SHOW_NEXT_LINE in
	2)
		QUALITY=$LINE
	;;
	1)
		BSSID=$LINE
		echo $BSSID $QUALITY >> $TMP
	;;
	esac
 	if [[ "$SSID" == "$LINE" ]]
	then
		SHOW_NEXT_LINE=3
	fi
	let SHOW_NEXT_LINE-=1
done

if [ ! -f $TMP ];
then
	echo Missing $TMP . Is $wlan down or is $SSID not in range? 
	exit 1
fi

bestAP_power=`cat $TMP | sort -n --key=2 | tail -n 1 | cut -d " " -f 1`
bestAP_MAC=`cat $TMP | sort -n --key=2 | tail -n 1 | cut -d " " -f 1`


AP_MAC=`iwconfig $wlan | grep "Access Point" | sed -n 's/.*Access Point\: \(.*\)\s/\1/p' | grep -o -E '([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}'`
echo The best AP is !$bestAP_MAC!
echo Currently connected to AP !$AP_MAC!

if [ "$AP_MAC" = "$bestAP_MAC" ]; then
	echo Already connected to best AP, doing nothing
else
	echo Reconnecting to AP $bestAP_MAC
	sudo ifconfig $wlan down
	sudo iwconfig $wlan essid $SSID ap "$bestAP_MAC"
	(sudo dhclient $wlan)&
	(sudo dhclient -6 $wlan)&
	
fi

rm $TMP
