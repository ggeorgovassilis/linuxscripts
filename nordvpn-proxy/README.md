Shell script & docker image for running haproxy with a nordvpn setup
============

Nordvpn is a VPN and SOCKS proxy provider (among other things). Unfortunately they keep changing the host names of their servers, which means that you have to either
use their app which takes care of network connectivity for you or look up the current server name yourself every time it changes. This script:

- looks up a currently valid nordvpn SOCKS5 server name
- runs haproxy with that configuration

Any applications can now connect to localhost:1080 using the SOCKS5 protocol, providing connection credentials.

##  Using the shell script

Prerequisites: haproxy, jq, curl

`./update-proxy.sh` 

##  Using the docker image

`docker run -t -i -p 1080:1080 georgovassilis/nordvpn-proxy:1`

(please look up the latest tag on docker hub)

##  Testing that it works

Edit "test-proxy.sh" replacing your credentials in the format "youremail@example.com:yourpassword"

`./test-proxy.sh localhost`