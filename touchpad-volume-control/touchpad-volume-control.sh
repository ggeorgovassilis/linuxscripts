#!/bin/bash

# Multi-touch volume control. This script requires read access to the event device. However you can't
# run this as root, because pactl needs access to the current user's PulseAudio.
# Requires that evtest is installed https://manpages.ubuntu.com/manpages/bionic/man1/evtest.1.html 
# Requires that amixer is installed. 
# Author: George Georgovassilis 
# Source code at: https://github.com/ggeorgovassilis/linuxscripts
# License: Public domain

echo Running "$0"

set -eu

# amixer doesn't allow fractional (eg 0.1%) relative volume changes. Since there are many scroll events per second, we can simulate this with delays
declare -r volume_up_change_interval_ms=50
declare -r volume_down_change_interval_ms=50

# We don't need unicode support, this will default to ASCII or smth
export LC_ALL=C

# Get current time in ms
now () {
  echo $(date +%s%3N)
}

last_volume_change_ts=$( now )

function find_touchpad_device () {
  echo end | sudo evtest 2>&1 | grep -i Touchpad | cut -d ':' -f 1
}

function abort_if_script_already_running (){

  local scriptname="$(basename "$(test -L "$0" && readlink "$0" || echo "$0")")"

  for pid in $(pidof -x "$scriptname"); do
    if [ "$pid" != "$$" ]; then
        echo "[$(date)] : $scriptname : Process is already running with PID $pid"
        exit 1
    fi
  done
}

function has_time_elapsed (){
  delta=$1
  now_ts=$( now )
  [[ $(( $now_ts - $last_volume_change_ts )) -gt $delta ]] && (last_volume_change_ts=$now_ts) && return 0
  return 1
}

function volume_up (){

  has_time_elapsed $volume_up_change_interval_ms || return 0
    
  pactl set-sink-volume @DEFAULT_SINK@ +0.5%


}

function volume_down (){
  has_time_elapsed $volume_down_change_interval_ms || return 0
  pactl set-sink-volume @DEFAULT_SINK@ -1%
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

# Event source device. Yours may vary. See https://wiki.ubuntu.com/DebuggingTouchpadDetection/evtest
# Used to be event7, after September update it keeps changing
declare -r touchpad_device=$(find_touchpad_device)

abort_if_script_already_running
read_events
