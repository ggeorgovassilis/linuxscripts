#!/bin/bash

# Multi-touch volume control. This script requires read access to the event device. However you can't
# run this as root, because amixer needs access to the current user's PulseAudio.
# Requires that evtest is installed https://manpages.ubuntu.com/manpages/bionic/man1/evtest.1.html 
# Author: George Georgovassilis 
# Repo: https://github.com/ggeorgovassilis/linuxscripts

echo Running $0
# Event source device. Yours may vary. See https://wiki.ubuntu.com/DebuggingTouchpadDetection/evtest
declare -r touchpad_device=/dev/input/event7

# Volume change per touchpad movement event
declare -r volume_up="+0.1%"
declare -r volume_down="-0.3%"

# Loudest volume in percent
declare -r loudest_volume="140"


# We don't need unicode support, this will default to ASCII or smth
export LC_ALL=C

function abort_if_script_already_running (){

  local scriptname="$(basename "$(test -L "$0" && readlink "$0" || echo "$0")")"

  for pid in $(pidof -x "$scriptname"); do
    if [ "$pid" != "$$" ]; then
        echo "[$(date)] : $scriptname : Process is already running with PID $pid"
        exit 1
    fi
  done
}

function volume_up (){
# cap maximum volume
current_volume=`pactl get-sink-volume @DEFAULT_SINK@ | grep -o -E "[0-9]+%" | head -1 | grep -o -E "[0-9]+"`
[[ $current_volume -lt $loudest_volume ]] && pactl set-sink-volume @DEFAULT_SINK@ "$volume_up"
}

function volume_down (){
pactl set-sink-volume @DEFAULT_SINK@ "$volume_down"
}

function process_line (){

  local line="$1"
  [[ "$line" == *"(BTN_TOOL_TRIPLETAP), value 1"* ]] && gesture_active=true
  [[ "$line" == *"(BTN_TOOL_TRIPLETAP), value 0"* ]] && gesture_active=false
  
# Two-finger gestures are used for scrolling, but sometimes they interfere with triple-finger gestures.
# If a two-finger gesture is detected, then it's safer to assume that three-finger gesture has been cancelled.
  [[ "$line" == *"(BTN_TOOL_DOUBLETAP)"* ]] && gesture_active=false

  local regex="\\(ABS_Y\\), value ([0-9]+)"
  if [[ $gesture_active == true && "$line" =~ $regex ]]; then
     local y="${BASH_REMATCH[1]}"
     [[ $y -lt previous_y ]] && volume_up
     [[ $y -gt previous_y ]] && volume_down
     previous_y=$y
  fi
}

function read_events (){
  local gesture_active=false
  local previous_y=0

# --line-buffered disables pipe buffering. Line buffering delays lines, so the read line loop doesn't see events in a timely manner
 
  sudo evtest "$touchpad_device" | grep --line-buffered 'BTN_TOOL_DOUBLETAP\|BTN_TOOL_TRIPLETAP\|ABS_Y' | while read line; \
  do process_line "$line"; \
  done < "${1:-/dev/stdin}" 

}

abort_if_script_already_running
read_events
