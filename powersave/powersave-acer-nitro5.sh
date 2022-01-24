#!/bin/sh

low_power()
{
powertop --auto-tune

cpupower frequency-set --max 800
echo off > /sys/devices/system/cpu/smt/control

rfkill block bluetooth
rmmod btusb
rmmod acer_wmi

echo 350 > /sys/class/drm/card0/gt_max_freq_mhz   
echo 350 > /sys/class/drm/card0/gt_boost_freq_mhz 

# lspci -vv to find pci device id

echo 1 > /sys/bus/pci/devices/0000:01:00.0/remove
}

medium_power()
{
powertop --auto-tune
echo off > /sys/devices/system/cpu/smt/control
cpupower frequency-set --max 1.6GHz

echo 400 > /sys/class/drm/card0/gt_max_freq_mhz   
echo 400 > /sys/class/drm/card0/gt_boost_freq_mhz 
}

full_power()
{
echo on > /sys/devices/system/cpu/smt/control
cpupower frequency-set --max 4GHz

modprobe btusb
rfkill unblock bluetooth

echo 800 > /sys/class/drm/card0/gt_max_freq_mhz   
echo 800 > /sys/class/drm/card0/gt_boost_freq_mhz 
}



case "$1" in
  low)
    echo reducing power
    low_power
  ;;
  medium)
    echo medium power
    medium_power
  ;;
  full)
    echo full power
    full_power
  ;;
  *)
    echo "Usage: powersave.sh {low|medium|full}" >&2
    exit 2
  ;;
esac


