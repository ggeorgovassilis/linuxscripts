#!/bin/sh
echo Adjusting volumes for usb-headset
case $1 in
"deferred")
	echo running deferred
	sleep 2
	su -c "pacmd set-sink-mute alsa_output.pci-0000_00_1b.0.analog-stereo 1" george
	su -c "pacmd set-sink-mute \"<alsa_output.usb-Logitech_Inc_Logitech_USB_Headset_H540_00000000-00-H540.analog-stereo\" 0" george
	;;
*)
	echo deferring
	($0 deferred)&
	;;
esac
