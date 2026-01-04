#!/bin/bash

# Multi-touch volume control. This script requires read access to the event device. However you can't
# run this as root, because pactl needs access to the current user's PulseAudio.
# Requires that evtest is installed https://manpages.ubuntu.com/manpages/bionic/man1/evtest.1.html 
# Requires that amixer is installed. 
# Author: George Georgovassilis 
# Source code at: https://github.com/ggeorgovassilis/linuxscripts
# License: Public domain

#!/bin/bash

# Optimized Multi-touch volume control
set -eu

# --- Configuration ---
declare -r threshold=20        # Sensitivity: Increase this to reduce CPU load (e.g., 60-100)
declare -r volume_step="2%"    # Change per "jump"
declare -r interval_ms=40      # Milliseconds between updates

# --- State Variables ---
last_volume_change_ts=$(date +%s%3N)
accumulated_y=0
gesture_active=false
previous_y=0

function find_touchpad_device () {
  echo end | sudo evtest 2>&1 | grep -i Touchpad | cut -d ':' -f 1 | head -n 1
}

function change_volume (){
  local direction=$1 # "+" or "-"
  local now=$(date +%s%3N)
  
  # Only fire if the time interval has passed
  if [[ $(( now - last_volume_change_ts )) -ge $interval_ms ]]; then
    pactl set-sink-volume @DEFAULT_SINK@ "${direction}${volume_step}"
    last_volume_change_ts=$now
  fi
}

function process_line (){
  local line="$1"

  # Gesture detection
  [[ "$line" == *"(BTN_TOOL_TRIPLETAP), value 1"* ]] && gesture_active=true && accumulated_y=0
  [[ "$line" == *"(BTN_TOOL_TRIPLETAP), value 0"* ]] && gesture_active=false
  [[ "$line" == *"(BTN_TOOL_DOUBLETAP)"* ]] && gesture_active=false

  # Movement processing
  local regex="\\(ABS_Y\\), value ([0-9]+)"
  if [[ $gesture_active == true && "$line" =~ $regex ]]; then
      local current_y="${BASH_REMATCH[1]}"
      
      # If previous_y is 0 (start of gesture), just set it and exit
      if [[ $previous_y -eq 0 ]]; then previous_y=$current_y; return; fi

      # Calculate movement delta
      local delta=$(( previous_y - current_y ))
      accumulated_y=$(( accumulated_y + delta ))

      # Only trigger volume change if movement exceeds threshold
      if [[ $accumulated_y -gt $threshold ]]; then
          change_volume "+"
          accumulated_y=0
      elif [[ $accumulated_y -lt $(( -threshold )) ]]; then
          change_volume "-"
          accumulated_y=0
      fi
      
      previous_y=$current_y
  else
      # Reset previous_y when gesture is not active
      previous_y=0
  fi
}

touchpad_device=$(find_touchpad_device)
echo "Monitoring $touchpad_device (Threshold: $threshold)"

# Using --line-buffered is critical for responsiveness
sudo evtest "$touchpad_device" | grep --line-buffered -E 'BTN_TOOL_DOUBLETAP|BTN_TOOL_TRIPLETAP|ABS_Y' | while read -r line; do
    process_line "$line"
done
