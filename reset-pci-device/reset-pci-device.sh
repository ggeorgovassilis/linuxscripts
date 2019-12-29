#!/bin/bash

if ! [ $(id -u) = 0 ]; then
   echo "Must be run as root"
   exit 1
fi

driver_name="ath10k_pci"
device_name="Atheros"
device_tree="/sys/devices"

echo Finding "$device_name" device number
device_number=`lspci -nn | grep "$device_name" | grep -E -o "^[0-9:.]+"`

device_path=`find "$device_tree" | grep "$device_number" | head -n 1`

echo Unloading driver module
rmmod -f "$driver_name"

echo Removing PCI device
echo 1 > "$device_path"/remove

echo Rescanning PCI device
echo 1 > /sys/bus/pci/rescan

echo Loading driver module
modprobe "$driver_name"
