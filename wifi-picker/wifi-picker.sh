#!/bin/bash
wlan=$1
SSID=$2
wifipassword=$3
iwlist $WLAN scan > /tmp/wlanlist
out=`tac /tmp/wlanlist | grep "$SSID\|Quality\|Address" | sed -n 's/.*ESSID\:\"\(.*\)\"\|.*Quality=\([0-9][0-9]\).*\|.*Address\: \(.*\)/\1\2\3/p'`
SHOW_NEXT_LINE=-1
BSSID=""
QUALITY=0
rm -f /tmp/wlanlist2
for LINE in ${out} ; do
	case $SHOW_NEXT_LINE in
	2)
		QUALITY=$LINE
	;;
	1)
		BSSID=$LINE
		echo $BSSID $QUALITY >> /tmp/wlanlist2
	;;
	esac
 	if [[ "$SSID" == "$LINE" ]]
	then
		SHOW_NEXT_LINE=3
	fi
	let SHOW_NEXT_LINE-=1
 
done

bestAP_power=`cat /tmp/wlanlist2 | sort -k2 | tail -n 1 | cut -c19-20`
bestAP_MAC=`cat /tmp/wlanlist2 | sort -k2 | tail -n 1 | cut -c1-17`


AP_MAC=`iwconfig | grep "Access Point" | sed -n 's/.*Access Point\: \(.*\)\s/\1/p' | grep -o -E '([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}'`
echo The best AP is !$bestAP_MAC!
echo Currently connected to AP !$AP_MAC!

if [ "$AP_MAC" = "$bestAP_MAC" ]; then
	echo Already connected to best AP, doing nothing
else
	echo Reconnecting to AP $bestAP_MAC
	sudo ifconfig $wlan down
	sudo iwconfig $wlan essid $SSID ap "$bestAP_MAC" key "$wifipassword"
	sudo dhclient $wlan
fi
