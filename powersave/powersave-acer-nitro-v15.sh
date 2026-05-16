#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "Restarting with sudo..."
   exec sudo "$0" "$@"
fi

# Your script logic starts here
echo "Running as root!"

function switch_off_nvidia(){
  pcid=$(lspci | grep NVIDIA | grep VGA | grep -oP '^\d+:\d+\.\d+')
    
  if [[ -n "$pcid" ]]; then
    echo Switching off nvidia GPU
    echo -n "1" > /sys/devices/pci0000:00/0000:00:01.1/0000:01:00.0/remove
  fi

  pcid=$(lspci | grep NVIDIA | grep Audio | grep -oP '^\d+:\d+\.\d+')
  if [[ -n "$pcid" ]]; then
    echo Switching off nvidia audio
    echo -n "1" > /sys/devices/pci0000:00/0000:00:01.1/0000:01:00.1/remove
  fi
  
}

function switch_off_ethernet() {
echo Unloading ethernet module
modprobe -r r8169
}


sudo powertop --auto-tune
sudo tlp bat
#switch_off_nvidia
switch_off_ethernet
