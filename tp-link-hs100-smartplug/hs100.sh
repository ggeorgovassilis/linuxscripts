#!/bin/bash

##
#  Switch the TP-LINK HS100 wlan smart plug on and off, query for status
#  Tested with firmware 1.0.8
#
#  Credits to Thomas Baust for the query/status/emeter commands
#
#  Author George Georgovassilis, https://github.com/ggeorgovassilis/linuxscripts

ip=$1
port=$2
cmd=$3

check_binaries() {
  command -v nc >/dev/null 2>&1 || { echo >&2 "The nc programme for sending data over the network isn't in the path, communication with the plug will fail"; exit 2; }
  command -v base64 >/dev/null 2>&1 || { echo >&2 "The base64 programme for decoding base64 encoded strings isn't in the path, decoding of payloads will fail"; exit 2; }
  command -v od >/dev/null 2>&1 || { echo >&2 "The od programme for converting binary data to numbers isn't in the path, the status and emeter commands will fail";}
  command -v read >/dev/null 2>&1 || { echo >&2 "The read programme for splitting text into tokens isn't in the path, the status and emeter commands will fail";}
  command -v printf >/dev/null 2>&1 || { echo >&2 "The printf programme for converting numbers into binary isn't in the path, the status and emeter commands will fail";}
}

# base64 encoded data to send to the plug to switch it on 
payload_on="AAAAKtDygfiL/5r31e+UtsWg1Iv5nPCR6LfEsNGlwOLYo4HyhueT9tTu36Lfog=="

# base64 encoded data to send to the plug to switch it off
payload_off="AAAAKtDygfiL/5r31e+UtsWg1Iv5nPCR6LfEsNGlwOLYo4HyhueT9tTu3qPeow=="

# base64 encoded data to send to the plug to query it
payload_query="AAAAI9Dw0qHYq9+61/XPtJS20bTAn+yV5o/hh+jK8J7rh+vLtpbr"

# base64 encoded data to query emeter - hs100 doesn't seem to support this in hardware, but the API seems to be there...
payload_emeter="AAAAJNDw0rfav8uu3P7Ev5+92r/LlOaD4o76k/6buYPtmPSYuMXlmA=="

usage() {
 echo Usage:
 echo $0 ip port on/off/check/status/emeter
 exit 1
}

checkarg() {
 name="$1"
 value="$2"

 if [ -z "$value" ]; then
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

check(){
  output=`sendtoplug $ip $port "$payload_query" | base64`
  if [[ $output == AAACJ* ]] ;
  then
     echo OFF
  fi
  if [[ $output == AAACK* ]] ;
  then
     echo ON
  fi
}

status(){
  payload="$1"
  code=171
  offset=4
  input_num=`sendtoplug $ip $port "$payload" | od --skip-bytes=$offset --address-radix=n -t u1 --width=9999`
  IFS=' ' read -r -a array <<< "$input_num"
  for element in "${array[@]}"
  do
    output=$(( $element ^ $code ))
    printf "\x$(printf %x $output)"
    code=$element
  done
}

##
#  Main programme
##
check_binaries
checkargs
case "$cmd" in
  on)
  sendtoplug $ip $port "$payload_on" > /dev/null
  ;;
  off)
  sendtoplug $ip $port "$payload_off" > /dev/null
  ;;
  check)
  check
  ;;	
  status)
  status "$payload_query"
  ;;
  emeter)
  status "$payload_emeter"
  ;;
  *)
  usage
  ;;
esac
exit 0

