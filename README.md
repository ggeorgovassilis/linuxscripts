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

Useful in a topology with a WLAN and multiple access points, will pick the AP with the strongest signal and connect. Must be run as root because iwlist
won't return a list of SSIDs otherwise.

```sh
wifi-picker.sh <interface> <SSID>
```

e.g.

```sh
sudo wifi-picker.sh wlan0 home_wifi
```

Note: You might need to restart some applications or even services after running the script, e.g. Firefox won't be able to connect to Google or Facebook.

## ip6-firewall

Example script that shows how to harden an ip6 enabled web server. Closes down everything other than port 22 (ssh), 80 (http), 6081 (varnish) and ICMP and redirects traffic from port 80 to 6081.

## some extra keyboard mappings

Example script from [here](http://larsmichelsen.com/open-source/german-umlauts-on-us-keyboard-in-x-ubuntu-10-04/) that adds some special characters
for European languages to an US keyboard mapping. 

## control the tp-link hs100, hs110 and hs200 wlan smart plugs

Script to connect over TCP/IP to an hs100/hs110 smart plug, switch it on and off and query status information. You'll need the IP address and port (was 9999 in my tests) and a command, e.g.:

Switch plug on:
```sh
hs100.sh 192.168.1.20 9999 on
```

Switch plug off:
```sh
hs100.sh 192.168.1.20 9999 off
```

Check if plug is on or off:
```sh
hs100.sh 192.168.1.20 9999 check
```

Print plug system status:
```sh
hs100.sh 192.168.1.20 9999 status
```

Print power consumption (not supported with my hs100 so not tested):
```sh
hs100.sh 192.168.1.20 9999 emeter
```

## tools for proxying a nordvpn socks5 proxy

Kind of esoteric, special need for one of my setups, but many it helps out someone with a similar need. I use, among others, nordvpn. They keep changing proxy names which makes long-running, persistent connections to their proxies impossible. Fortunately they expose an API over which available proxies can be queried, so my setup consists of an haproxy which forwards TCP traffic to their proxy and a script which queries the API and updates the haproxy configuration.

```sh
update-proxy.sh
``` 

Snoop around the nordvpn-proxy directory for other tools.

