#!/bin/bash

##
#  Switch the TP-LINK HS100 wlan smart plug on and off
#  Tested with firmware 1.0.8
#
ip=$1
port=$2
cmd=$3

check_binaries() {
  command -v nc >/dev/null 2>&1 || { echo >&2 "The nc programme for sending data over the network isn't installed"; exit 2; }
  command -v base64 >/dev/null 2>&1 || { echo >&2 "The base64 programme for decoding base64 encoded strings isn't installed"; exit 2; }
}

payload_on="AAAAKtDygfiL/5r31e+UtsWg1Iv5nPCR6LfEsNGlwOLYo4HyhueT9tTu36Lfog=="

payload_off="AAAAKtDygfiL/5r31e+UtsWg1Iv5nPCR6LfEsNGlwOLYo4HyhueT9tTu3qPeowAAAC3Q8oH4i/+a
99XvlLbFoNSL+Zzwkei3xLDRpcDi2KOB5Jbku9i307aUrp7jnuM="

payload_query="AAAAI9Dw0qHYq9+61/XPtJS20bTAn+yV5o/hh+jK8J7rh+vLtpbr"


usage() {
 echo Usage:
 echo $0 ip port on/off/query
 exit 1
}

checkarg() {
 name="$1"
 value="$2"

 if [ -z "$value" ]
  then
    echo "missing argument $name"
    usage
 fi
}

checkargs() {
  checkarg "ip" $ip
  checkarg "port" $port
  checkarg "command" $cmd
}

sendtoplug() {
  ip="$1"
  port="$2"
  payload="$3"
  echo -n "$payload" | base64 -d | nc -v $ip $port  || echo couldn''t connect to $ip:$port, nc failed with exit code $?
}


##
#  Main programme
##
checkargs
case "$cmd" in
  on)
  sendtoplug $ip $port "$payload_on" > /dev/null
  ;;
  off)
  sendtoplug $ip $port "$payload_off" > /dev/null
  ;;
  query)
  output=`sendtoplug $ip $port "$payload_query" | base64`
  if [[ $output == AAACJ* ]] ;
  then
     echo OFF
  fi
  if [[ $output == AAACK* ]] ;
  then
     echo ON
  fi

  ;;
  *)
  usage
  ;;
esac
exit 0

