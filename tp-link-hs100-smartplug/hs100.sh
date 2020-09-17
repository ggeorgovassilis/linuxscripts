#!/bin/bash
##
#  Controls TP-LINK HS100,HS110, HS200 wlan smart plugs
#  Tested with HS100 firmware 1.0.8
#
#  Credits to Thomas Baust for the query/status/emeter commands
#
#  Author George Georgovassilis, https://github.com/ggeorgovassilis/linuxscripts

echo args are $@ 
ip=$1
port=$2
cmd=$3

# encoded (the reverse of decode) commands to send to the plug

# encoded {"system":{"set_relay_state":{"state":1}}}
payload_on="AAAAKtDygfiL/5r31e+UtsWg1Iv5nPCR6LfEsNGlwOLYo4HyhueT9tTu36Lfog=="

# encoded {"system":{"set_relay_state":{"state":0}}}
payload_off="AAAAKtDygfiL/5r31e+UtsWg1Iv5nPCR6LfEsNGlwOLYo4HyhueT9tTu3qPeow=="

# encoded { "system":{ "get_sysinfo":null } }
payload_query="AAAAI9Dw0qHYq9+61/XPtJS20bTAn+yV5o/hh+jK8J7rh+vLtpbr"

# the encoded request { "emeter":{ "get_realtime":null } }
payload_emeter="AAAAJNDw0rfav8uu3P7Ev5+92r/LlOaD4o76k/6buYPtmPSYuMXlmA=="

# tools

check_dependencies() {
  command -v nc >/dev/null 2>&1 || { echo >&2 "The nc programme for sending data over the network isn't in the path, communication with the plug will fail"; exit 2; }
  command -v base64 >/dev/null 2>&1 || { echo >&2 "The base64 programme for decoding base64 encoded strings isn't in the path, decoding of payloads will fail"; exit 2; }
  command -v od >/dev/null 2>&1 || { echo >&2 "The od programme for converting binary data to numbers isn't in the path, the status and emeter commands will fail";}
  command -v read >/dev/null 2>&1 || { echo >&2 "The read programme for splitting text into tokens isn't in the path, the status and emeter commands will fail";}
  command -v printf >/dev/null 2>&1 || { echo >&2 "The printf programme for converting numbers into binary isn't in the path, the status and emeter commands will fail";}
}

show_usage() {
  echo Usage: $0 IP PORT COMMAND
  echo where COMMAND is one of on/off/check/status/emeter/toggle
  exit 1
}


check_arguments() {
   check_arg() {
    name="$1"
    value="$2"
    if [ -z "$value" ]; then
       echo "missing argument $name"
       show_usage
    fi
   }
   check_arg "ip" $ip
   check_arg "port" $port
   check_arg "command" $cmd
}

send_to_plug() {
   ip="$1"
   port="$2"
   payload="$3"
   echo -n "$payload" | base64 --decode | nc -v $ip $port || echo couldn''t connect to $ip:$port, nc failed with exit code $?
}

decode(){
   code=171
   offset=4
   input_num=`od -j $offset -An -t u1 -v | tr "\n" " "`
   IFS=' ' read -r -a array <<< "$input_num"
   args_for_printf=""
   for element in "${array[@]}"
   do
     output=$(( $element ^ $code ))
     args_for_printf="$args_for_printf\x$(printf %x $output)"
     code=$element
   done
     printf "$args_for_printf"
}

query_plug(){
   payload=$1
   send_to_plug $ip $port "$payload" | decode
}

# plug commands

cmd_print_plug_relay_state(){
   output=`send_to_plug $ip $port "$payload_query" | decode | egrep -oa 'relay_state":[0,1]' | egrep -o '[0,1]'`
   if [[ $output -eq 0 ]]; then
     echo OFF
   elif [[ $output -eq 1 ]]; then
     echo ON
   else
     echo Couldn''t understand plug response $output
   fi
}

cmd_print_plug_status(){
     query_plug "$payload_query"
}

cmd_print_plug_consumption(){
     query_plug "$payload_emeter"
}

cmd_switch_on(){
     send_to_plug $ip $port $payload_on > /dev/null
}

cmd_switch_off(){
     send_to_plug $ip $port $payload_off > /dev/null
}

cmd_switch_toggle() {
   output=`cmd_print_plug_relay_state`
   if [[ $output == OFF ]]; then
     cmd_switch_on
   elif [[ $output == ON ]]; then
     cmd_switch_off
   else
     echo $output
   fi
}

##
#  Main programme
##


check_dependencies
check_arguments

case "$cmd" in
  on)
     cmd_switch_on
     ;;
  off)
     cmd_switch_off
     ;;
  toggle)
     cmd_switch_toggle
     ;;
  check)
     cmd_print_plug_relay_state
     ;;	
  status)
     cmd_print_plug_status
     ;;
  emeter)
     cmd_print_plug_consumption
     ;;
  *)
     show_usage
     ;;
esac
