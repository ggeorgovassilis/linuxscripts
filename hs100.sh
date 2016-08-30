#!/bin/bash

set -o errexit

##
#  Switch the TP-LINK HS100 wlan smart plug on and off, query for status
#  Tested with firmware 1.0.8
#
#  Credits to Thomas Baust for the query/status/emeter commands
#
#  Author George Georgovassilis, https://github.com/ggeorgovassilis/linuxscripts

# encoded (the reverse of decode) commands to send to the plug

# encoded {"system":{"set_relay_state":{"state":1}}}
payload_on="AAAAKtDygfiL/5r31e+UtsWg1Iv5nPCR6LfEsNGlwOLYo4HyhueT9tTu36Lfog=="

# encoded {"system":{"set_relay_state":{"state":0}}}
payload_off="AAAAKtDygfiL/5r31e+UtsWg1Iv5nPCR6LfEsNGlwOLYo4HyhueT9tTu3qPeow=="

# encoded { "system":{ "get_sysinfo":null } }
payload_query="AAAAI9Dw0qHYq9+61/XPtJS20bTAn+yV5o/hh+jK8J7rh+vLtpbr"

# the encoded request { "emeter":{ "get_realtime":null } }
payload_emeter="AAAAJNDw0rfav8uu3P7Ev5+92r/LlOaD4o76k/6buYPtmPSYuMXlmA=="

# BSD base64 decode on osx has different options
case $OSTYPE in
   darwin*)  BASE64DEC="-D";;
   *)        BASE64DEC="-d";;
esac

# netcat options
timeout=2
NCOPTS='-v' # verbose
NCOPTS+=" -G $timeout"

# tools

error(){
   echo >&2 "$@"
   exit 2
}

quiet(){
   $@ >/dev/null 2>&1
}

check_dependencies() {
   quiet command -v nc \
      || error "The nc programme for sending data over the network isn't" \
               "in the path, communication with the plug will fail"
   quiet command -v base64 \
      || error "The base64 programme for decoding base64 encoded strings isn't" \
               "in the path, decoding of payloads will fail"
   quiet command -v od \
      || error "The od programme for converting binary data to numbers isn't" \
               "in the path, the status and emeter commands will fail"
   quiet command -v read \
      || error "The read programme for splitting text into tokens isn't" \
               "in the path, the status and emeter commands will fail"
   quiet command -v printf \
      || error "The printf programme for converting numbers into binary isn't"\
               "in the path, the status and emeter commands will fail"
}

usage() {
   echo Usage: $0 IP PORT COMMAND
   echo where COMMAND is one of on/off/check/status/emeter
   exit 1
}

check_arguments() {
   check_arg() {
      name="$1"
      value="$2"
      if [ -z "$value" ]; then
         echo "missing argument $name"
         usage
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
   echo -n "$payload" | base64 ${BASE64DEC} | nc $NCOPTS $ip $port || echo couldn''t connect to $ip:$port, nc failed with exit code $?
}

decode(){
   code=171
   offset=4
   input_num=`od --skip-bytes=$offset --address-radix=n -t u1 --width=9999`
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
cmd_discover(){
    myip=`~/cantrips/myip.sh`
    subnet=${myip%%.[0-9]}.0-255
    hs100ip=$(nmap -p ${port} --open ${subnet} \
                | grep 'Nmap scan report for' \
                | egrep -o '(([0-9]{1,3}\.){3}[0-9]{1,3})' ) \
        || error "Could not find any hs100 plugs"
    # if we can, add this to /etc/hosts
    if ! [ -w /etc/hosts ]
    then
        echo $hs100ip
        return 0
    fi

    if [[ ${#hs100ip} = 1 ]]
    then
        hs100host=hs100
        # remove previous host entry, and add new one
        sed -i '/'$hs100host'/d' /etc/hosts
        echo ${hs100ip}'\t'${hs100host} >> /etc/hosts
        echo $hs100host
    else
        for ip in ${hs100ip[@]}
        do
        # ok there are multiple HS100 plugs on the network
        # we'll append a shasum hash of the MAC address to make hs100host unique

        # since we just hit it with nmap, it should be in the arp cache
        mac=$(arp -a \
                | grep "($hs100ip)" \
                | egrep -o '(([0-9a-fA-F]{1,2}:){5}[0-9a-fA-F]{1,2})' )
        [ -z "$mac" ] && error "arp didn't find a MAC!"
        echo "mac $mac"

        # use the first 7 characters of the shasum as unique ID
        hash=$(echo $mac | shasum)
        hs100host=hs100${hash:0:7}
        echo $hs100host

        # remove previous host entry, and add new one
        sed -i '/'$hs100host'/d' /etc/hosts
        echo ${hs100ip}'\t'${hs100host} >> /etc/hosts
        echo $hs100host

        done
    fi

    return 0
}

cmd_print_plug_relay_state(){
   output=`send_to_plug $ip $port "$payload_query" | base64`
   if [[ $output == AAACJ* ]]; then
      echo OFF
   elif [[ $output == AAACK* ]]; then
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

# run the Main progamme, if we are not being sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then

# process args with getopt(1). See `man getopt`
args=`getopt qvi:p: $*` || { usage; exit 1; }
set -- $args

for i #in $@
do
    case "$i" in 
    -q) opt_quiet=yes; shift;;
    -v) set -o xtrace; shift;;
    -i) ip=$2; shift; shift;;
    -p) port=$2; shift; shift;;
    --) shift; break;;
    #*)  error "Getopt broke! Found $i"
    esac
done

: ${ip=hs100}
: ${port=9999}
cmd=$1

check_dependencies
check_arguments

case "$cmd" in
  discover) cmd_discover;;
  on)       cmd_switch_on;;
  off)      cmd_switch_off;;
  check)    cmd_print_plug_relay_state;;
  status)   cmd_print_plug_status;;
  emeter)   cmd_print_plug_consumption;;
  *)        usage;;
esac

fi # end main program
