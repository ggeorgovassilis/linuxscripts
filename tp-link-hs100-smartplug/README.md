Command line client for the tp-link hs100, hs110 and hs200 wifi plug
============

Script to connect over TCP/IP to an hs100, hs103, hs110, hs200 and KP105 smart plugs, switch it on and off and query status information. You'll need the IP address and port (was 9999 in my tests) and a command, e.g.:

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
There are [reports](https://github.com/ggeorgovassilis/linuxscripts/issues/13) that this doesn't work with newer firmware

Print plug system status:
```sh
hs100.sh 192.168.1.20 9999 status
```

Print power consumption (not supported with my hs100 so not tested):
```sh
hs100.sh 192.168.1.20 9999 emeter
```
## Running with docker

`docker run -it georgovassilis/hs100:latest 192.168.1.20 9999 on`
