#!/bin/bash

# Default frequency if no valid parameter is given
FREQUENCY="2000MHz" # Default to normal

function log(){
echo "$1" >&2
}

function get_current_frequency(){
cpupower frequency-info | grep -oP 'frequency should be within \d+.\d+ (GHz|MHz) and \K(\d+.\d+) (GHz|MHz)' | awk '{
    value = $1;
    unit = $2;
    if (unit == "GHz") {
        print value * 1000;
    } else {
        print value;
    }
}'
}

function up(){
f=$(get_current_frequency)
log "current F $f"
if [[ "$f" -lt "501" ]]; then
  f=1000
elif [[ "$f" -lt "1001" ]]; then
  f=2000
elif [[ "$f" -lt "2001" ]]; then
  f=3000
else
  f=4000
fi
echo "$f"MHz
}

function down(){
f=$(get_current_frequency)
if [[ "$f" -gt "3999" ]]; then
  f=3000
elif [[ "$f" -gt "2999" ]]; then
  f=2000
elif [[ "$f" -gt "1999" ]]; then
  f=1000
else
  f=500
fi
echo "$f"MHz
}


function handle_parameters(){
if [ -z "$1" ]; then
    echo "No parameter provided. Setting frequency to default (2GHz)."
else
    case "$1" in
        "low")
            FREQUENCY="1000MHz"
            ;;
        "normal")
            FREQUENCY="2000MHz"
            ;;
        "high")
            FREQUENCY="3000MHz"
            ;;
        "max")
            FREQUENCY="4000MHz"
            ;;
        "up")
            FREQUENCY=$(up)
            ;;
        "down")
            FREQUENCY=$(down)
            ;;
        *)
            echo "Invalid parameter: $1. Allowed parameters are low, normal, high, max, up, down"
            exit 1
            ;;
    esac
fi

echo "Setting CPU max frequency to $FREQUENCY..."
cpupower frequency-set --max "$FREQUENCY"

if [ $? -eq 0 ]; then
    echo "CPU frequency set successfully to $FREQUENCY."
    echo "CPU $FREQUENCY" | osd_cat -p top -o 20 -c green -d 1 -f "-*-helvetica-bold-r-*-*-48-*-*-*-*-*-*-*"
else
    echo "Failed to set CPU frequency. You might need to run this script with sudo."
    echo "Failed to set CPU frequency" | osd_cat -p top -o 20 -c red -d 1 -f "-*-helvetica-bold-r-*-*-48-*-*-*-*-*-*-*"
fi

}

handle_parameters "$@"
