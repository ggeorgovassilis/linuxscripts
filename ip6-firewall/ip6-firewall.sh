#!/bin/bash
IPT6="/sbin/ip6tables"
PUBIF="eth0"
echo "Starting IPv6 firewall..."
$IPT6 -F
$IPT6 -X
$IPT6 -t mangle -F
$IPT6 -t mangle -X
$IPT6 -t nat -F
$IPT6 -t nat -X

#unlimited access to loopback
$IPT6 -A INPUT -i lo -j ACCEPT
$IPT6 -A OUTPUT -o lo -j ACCEPT
 
# DROP all incomming traffic
$IPT6 -P INPUT DROP
$IPT6 -P OUTPUT DROP
$IPT6 -P FORWARD DROP
 
# Allow full outgoing connection but no incomming stuff
$IPT6 -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
$IPT6 -A OUTPUT -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
 
# allow incoming ICMP ping pong stuff
$IPT6 -A INPUT -p ipv6-icmp -j ACCEPT
$IPT6 -A OUTPUT -p ipv6-icmp -j ACCEPT
 
############# add your custom rules below ############
### open IPv6  port 80 
$IPT6 -A INPUT -p tcp --destination-port 80 -j ACCEPT

$IPT6 -A INPUT -p tcp --destination-port 6081 -j ACCEPT

### open IPv6  port 22
$IPT6 -A INPUT -p tcp --destination-port 22 -j ACCEPT

############ End custom rules ################

#redirect ports

#old, failed experiments
#$IPT6 -t mangle -A PREROUTING -p tcp --dport 80 -j TPROXY --on-port 6081
#ip6tables -t nat -A PREROUTING -i sixxs -p tcp --dport 80 -j DNAT --to-destination [2a01:4f8:d12:11c6::2]:6081

$IPT6 -t nat -A PREROUTING -p tcp --dport 80 -m cpu --cpu 0 -j REDIRECT --to-port 6081 


#### no need to edit below ###
# log everything else

$IPT6 -N LOGGING
$IPT6 -A INPUT -j LOGGING
$IPT6 -A LOGGING -m limit --limit 2/min -j LOG --log-prefix "IPTables-Dropped: " --log-level 4
$IPT6 -A LOGGING -j DROP

