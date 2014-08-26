linuxscripts
============

Script collection for linux


## powersave

Enables some powersaving on the Asus N56VB and Ubuntu 12.04. Should work on other computers and Linuxes as well. In order to enable power saving run the script with an argument of either light, on or extra like this:

```sh
powersave.sh light
```

The script contains self-explanatory functions grouped under a big CASE that enable various power saving features. Depending on your needs, you can re-arrange these functions to different cases. For example, I work mostly in a wireless setup, so I moved the "disable_ethernet" function to the "light" case. Also, when on the road, I don't do heavy processing, so I moved "make_cpus_sleep" to the "on" case - however my applications need a lot of CPU at work, so I'm not running the "make_cpus_sleep" function in the "light" setting. 

## brightness

Allows for finer brightness control for the Asus N56VB and Ubuntu 12.04. You probably need to adjust the "B" variable in the script.

```sh
brightness.sh down
```

## usb-headset

Handles some automatic volume adjustment (like enabling the headset and muting other equipment). You probably will have to adjust the device names.

## wifi-picker

Useful in a topology with a WLAN and multiple access points, will pick the AP with the strongest signal and connect.

```sh
wifi-picker.sh <interface> <SSID> <password>
```

ie

```sh
wifi-picker.sh wlan0 home_wifi unguessablepa55word
```