#!/bin/bash

touchpad_device=/dev/input/event7
touch_happening=false
previous_y=0

regex="\\(ABS_Y\\), value ([0-9]+)"

function process_line (){
if [[ $1 == *"(BTN_TOOL_TRIPLETAP), value 1"* ]]; then
  echo Detected triple touch gesture start
  touch_happening=true
elif [[ $1 == *"(BTN_TOOL_TRIPLETAP), value 0"* ]]; then
  echo Detected triple touch gesture stop
  touch_happening=false
fi

if [[ $touch_happening == true && $1 =~ $regex ]]; then
   y="${BASH_REMATCH[1]}"
   if [[ $y -lt previous_y ]]; then
	amixer --quiet -D pulse sset Master 1%+
   fi
   if [[ $y -gt previous_y ]]; then
	amixer --quiet -D pulse sset Master 1%-
   fi
   previous_y=$y
fi

}

# --line-buffered disables pipe buffering. Line buffering delays lines, so the read line loop doesn't see events in a timely manner
 
sudo evtest "$touchpad_device" | grep --line-buffered -v 'MSC_TIMESTAMP\|SYN_REPORT' | grep --line-buffered 'BTN_TOOL_TRIPLETAP\|ABS_Y\|BTN_FINGER' | while read line; \
do \
  process_line "$line"; \
done < "${1:-/dev/stdin}" 

