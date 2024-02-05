#!/bin/bash

# Toggles between keyboard layouts. This is a workaround for broken behaviour in Ubuntu 22.04 (Feb 2024).
# Author: George Georgovassilis 
# Source code at: https://github.com/ggeorgovassilis/linuxscripts
# License: Public domain

echo Running "$0"

declare -r LAYOUT_1="gr"
declare -r LAYOUT_2="us"

# We don't need unicode support, this will default to ASCII or smth
export LC_ALL=C

function find_keyboard_device () {
  echo end | sudo evtest 2>&1 | grep -i keyboard | cut -d ':' -f 1
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

function toggle_keyboard_layout (){
  local is_layout1=$(setxkbmap -query | grep layout | grep -i "$LAYOUT_1")
  [[ $is_layout1 ]] && setxkbmap -layout "$LAYOUT_2"
  [[ -z $is_layout1 ]] && setxkbmap -layout "$LAYOUT_1"
}

function process_line (){
  local line="$1"
  [[ "$line" == *"(KEY_LEFTALT), value 1"* ]] && ((key_combo_level++))
  [[ "$line" == *"(KEY_LEFTALT), value 0"* ]] && ((key_combo_level--))
  [[ "$line" == *"(KEY_LEFTSHIFT), value 1"* ]] && ((key_combo_level++))
  [[ "$line" == *"(KEY_LEFTSHIFT), value 0"* ]] && ((key_combo_level--))
  [[ $key_combo_level == 2 ]] && toggle_keyboard_layout
}

function read_events (){
  local key_combo_level=0

# --line-buffered disables pipe buffering. Line buffering delays lines, so the read line loop doesn't see events in a timely manner
 
  sudo evtest "$keyboard_device" | grep --line-buffered 'KEY_LEFTALT\|KEY_LEFTSHIFT' | while read line; \
  do process_line "$line"; \
  done < "${1:-/dev/stdin}" 
}

# Event source device. Yours may vary. See https://wiki.ubuntu.com/DebuggingTouchpadDetection/evtest
# Used to be event7, after September update it keeps changing
declare -r keyboard_device=$(find_keyboard_device)

abort_if_script_already_running
read_events

