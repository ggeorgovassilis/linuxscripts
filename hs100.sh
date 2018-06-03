#!/bin/bash

set -o errexit

(( "$DEBUG" )) && set -o xtrace

here=$(cd $(dirname $BASH_SOURCE[0]); echo $PWD)

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
# BSD od (octal dump) on osx has different options
od_offset=4
# BSD netcat on osx has different options
nc_timeout=2
NCOPTS=""
#NCOPTS+='-v' # verbose
case $OSTYPE in
   darwin*)
      BASE64DEC="-D"
      ODOPTS="-j $od_offset -A n -t u1"
      NCOPTS+=" -G $nc_timeout"
      ;;
   linux*)
      BASE64DEC="-d"
      ODOPTS="--skip-bytes=$od_offset --address-radix=n -t u1 --width=9999"
      NCOPTS+=" -w $nc_timeout"
      ;;
esac


# tools

error(){
   echo >&2 "$@"
   exit 2
}

quiet(){
   $@ >/dev/null 2>&1
}

mac_from_ip()
{
    # if you've contacted an IP recently, the arp cache has juicy info
    local ip=$1
    mac=$(arp -a \
            | grep "($ip)" \
            | egrep -o '(([0-9a-fA-F]{1,2}:){5}[0-9a-fA-F]{1,2})' )
    [ -z "$mac" ] && { echo 2>&1 "arp didn't find a MAC for $ip!"; return 1; }
    echo $mac
}

unique_hostname()
{
    # given a prefix and a MAC for a host, construct a unique name for the host
    local prefix=$1;    [ -n $prefix ] || return 1
    local mac=$2;       [ -n $mac ] || return 1

    # use the first 7 characters of the shasum as unique ID
    hash=$(echo $mac | shasum)
    hs100host=hs100${hash:0:7}
    echo $hs100host
}

host_entry()
{
    host=$1
    ip=$2
    printf "${ip}\t${host}\n" >> /etc/hosts
    echo plug $host has ip $ip
}

my_plugs()
{
    cat /etc/hosts | grep hs100 | awk '{ print $2 }'
}

check_dependency()
{
    dep=$1; shift
    message=$@
    quiet command -v "$dep" || error "$message"
}

check_dependencies() {
    check_dependency nc \
       "The nc programme for sending data over the network isn't" \
       "in the path, communication with the plug will fail"
    check_dependency base64 \
       "The base64 programme for decoding base64 encoded strings isn't" \
       "info the path, decoding of payloads will fail"
    check_dependency od \
        "The od programme for converting binary data to numbers isn't" \
        "in the path, the status and emeter commands will fail"
    check_dependency nmap \
        "The nmap programme for mapping networks isn't"\
        "in the path, the discover command will fail"
    check_dependency shasum \
        "The shasum programme for hashing strings isn't"\
        "in the path, the sudo discover command will fail"
    check_dependency arp \
        "The arp programme to access Address Resolution Protocol cache isn't"\
        "in the path, the sudo discover command will fail"
}

usage() {
   echo "Usage: $0 [-i IP] [-p PORT] COMMAND"
   echo "where COMMAND is one of: ${commands[@]}"
   exit 1
}

check_arg() {
   name="$1"
   value="$2"
   if [ -z "$value" ]; then
      echo "missing argument $name"
      usage
   fi
}

# Check for a single string in a list of space-separated strings.
# e.g. has "foo" "foo bar baz" is true, but has "f" "foo bar baz" is not.
# from https://chromium.googlesource.com/chromiumos/platform/crosutils/+/master/common.sh
has()
{ [[ " ${*:2} " == *" $1 "* ]]; }

check_command()
{ has "$1" "$commands"; }

send_to_plug() {
   ip="$1"
   port="$2"
   payload="$3"
   if ! echo -n "$payload" | base64 ${BASE64DEC} | nc $NCOPTS $ip $port
   then
      echo couldn''t connect to $ip:$port, nc failed with exit code $?
   fi
}

decode(){
   code=171
   input_num=`od $ODOPTS`
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

pretty_json()
{
    # read from stdin
    if quiet command -v python
    then
         python -m json.tool
    else
         cat
         echo
    fi
}

query_plug(){
   payload=$1
   check_dependency od \
       "The od programme for converting binary data to numbers isn't" \
       "in the path, the status and emeter commands will fail"
   check_arg "ip" $plugs
   check_arg "port" $port
   for ip in ${plugs[@]}
   do
        send_to_plug $ip $port "$payload" | decode | pretty_json
   done
}

# plug commands
cmd_discover(){
    check_arg "port" $port
    check_dependency nmap \
        "The nmap programme for mapping networks isn't"\
        "in the path, the discover command will fail"
    myip="`${here}/myip.sh`"
    subnet=$(echo $myip | egrep -o '([0-9]{1,3}\.){3}')
    subnet=${subnet}0-255
    declare -a hs100ip
    hs100ip=( $(nmap -Pn -p ${port} --open ${subnet} \
                | grep 'Nmap scan report for' \
                | egrep -o '(([0-9]{1,3}\.){3}[0-9]{1,3})' ) \
            ) \
        || error "Could not find any hs100 plugs"

    # if we can't write this to /etc/hosts, echo what we found and quit
    if ! [ -w /etc/hosts ]
    then
        echo HS100 plugs found: ${hs100ip[@]}
        return 0
    fi

    check_dependency shasum \
        "The shasum programme for hashing strings isn't"\
        "in the path, the sudo discover command will fail"
    check_dependency arp \
        "The arp programme to access Address Resolution Protocol cache isn't"\
        "in the path, the sudo discover command will fail"

    # remove existing hs100* hosts entries
    sed -i.bak /hs100/d /etc/hosts

    if [[ ${#hs100ip[@]} = 1 ]]
    then
        host_entry hs100 $hs100ip
        return 0
    fi

    # multiple HS100 plugs on the network, hash MAC address for unique hostname
    for ip in ${hs100ip[@]}
    do
        # since we just hit it with nmap, it should be in the arp cache
        mac=`mac_from_ip $ip`
        hs100host=`unique_hostname hs100 $mac`
        host_entry $hs100host $ip
    done
    return 0
}

cmd_print_plug_relay_state(){
   check_arg "ip" $plugs
   check_arg "port" $port
   for ip in ${plugs[@]}
   do
       printf "$ip\t"
       output=`send_to_plug $ip $port "$payload_query" \
               | decode \
               | egrep -o 'relay_state":[0,1]' \
               | egrep -o '[0,1]'`
       if (( output == 0 )); then
         echo OFF
       elif (( output == 1 )); then
         echo ON
       else
         echo Couldn''t understand plug response $output
       fi
   done
}

cmd_print_plug_status(){
   query_plug "$payload_query"
}

cmd_print_plug_consumption(){
   query_plug "$payload_emeter"
}

cmd_switch_on(){
   check_arg "ip" $plugs
   check_arg "port" $port
   for ip in ${plugs[@]}
   do
      send_to_plug $ip $port $payload_on > /dev/null
   done
}

cmd_switch_off(){
   check_arg "ip" $plugs
   check_arg "port" $port
   for ip in ${plugs[@]}
   do
       send_to_plug $ip $port $payload_off > /dev/null
   done
}

commands=" on off check status emeter discover list "

# run the Main progamme, if we are not being sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then

# process args with getopt(1). See `man getopt`
args=`getopt qvi:p: $*` || { usage; exit 1; }
set -- $args

declare -a plugs;

for i #in $@
do
    case "$i" in
    -q) opt_quiet=yes; shift;;
    -v) set -o xtrace; shift;;
    -i) plugs=$2; shift; shift;;
    -p) port=$2; shift; shift;;
    --) shift; break;;
    #*)  error "Getopt broke! Found $i"
    esac
done

: ${plugs=`my_plugs`}
: ${port=9999}
cmd=$1

#check_dependencies

check_dependency nc \
   "The nc programme for sending data over the network isn't" \
   "in the path, communication with the plug will fail"
check_dependency base64 \
   "The base64 programme for decoding base64 encoded strings isn't" \
   "info the path, decoding of payloads will fail"

check_arg "command" $cmd
check_command $cmd

case "$cmd" in
  discover) cmd_discover;;
  list)     plugs=`my_plugs`; for p in ${plugs[@]}; do echo $p; done;;
  on)       cmd_switch_on;;
  off)      cmd_switch_off;;
  check)    cmd_print_plug_relay_state;;
  status)   cmd_print_plug_status;;
  emeter)   cmd_print_plug_consumption;;
  *)        usage;;
esac

fi # end main program
