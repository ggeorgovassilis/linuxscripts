Command line client for the tp-link hs100, hs110 and hs200 wifi plug
============

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
