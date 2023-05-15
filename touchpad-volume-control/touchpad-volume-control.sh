#!/bin/bash

# Multi-touch volume control. This script requires read access to the event device. However you can't
# run this as root, because amixer needs access to the current user's PulseAudio.
# Requires that evtest is installed https://manpages.ubuntu.com/manpages/bionic/man1/evtest.1.html 
# Author: George Georgovassilis 
# Repo: https://github.com/ggeorgovassilis/linuxscripts

# Event source device. Yours may vary. See https://wiki.ubuntu.com/DebuggingTouchpadDetection/evtest
touchpad_device=/dev/input/event7

# Volume change per touchpad movement event
volume_d="1%"
gesture_active=false
previous_y=0

regex="\\(ABS_Y\\), value ([0-9]+)"

function abort_if_script_already_running (){

  scriptname="$(basename "$(test -L "$0" && readlink "$0" || echo "$0")")"

  for pid in $(pidof -x "$scriptname"); do
    if [ $pid != $$ ]; then
        echo "[$(date)] : $scriptname : Process is already running with PID $pid"
        exit 1
    fi
  done
}

function volume_up (){
  amixer --quiet -D pulse sset Master "$volume_d"+
}

function volume_down (){
  amixer --quiet -D pulse sset Master "$volume_d"-
}

function process_line (){

  line="$1"
  if [[ "$line" == *"(BTN_TOOL_TRIPLETAP), value 1"* ]]; then
    gesture_active=true
  elif [[ "$line" == *"(BTN_TOOL_TRIPLETAP), value 0"* ]]; then
    gesture_active=false
  fi

  if [[ $gesture_active == true && "$line" =~ $regex ]]; then
     y="${BASH_REMATCH[1]}"
     [[ $y -lt previous_y ]] && volume_up
     [[ $y -gt previous_y ]] && volume_down
     previous_y=$y
  fi
}

function read_events (){
  
# --line-buffered disables pipe buffering. Line buffering delays lines, so the read line loop doesn't see events in a timely manner
 
  evtest "$touchpad_device" | grep --line-buffered 'BTN_TOOL_TRIPLETAP\|ABS_Y' | while read line; \
  do process_line "$line"; \
  done < "${1:-/dev/stdin}" 

}

abort_if_script_already_running
read_events
