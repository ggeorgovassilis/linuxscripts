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

for x in /sys/devices/system/cpu/cpu[2-9]*/online; do
  echo 0 >"$x"
done
}

medium_power()
{
powertop --auto-tune
echo off > /sys/devices/system/cpu/smt/control

for x in /sys/devices/system/cpu/cpu[1-2]*/online; do
  echo 1 >"$x"
done

for x in /sys/devices/system/cpu/cpu[3-9]*/online; do
  echo 0 >"$x"
done

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
for x in /sys/devices/system/cpu/cpu[1-9]*/online; do
  echo 1 >"$x"
done
}



case "$1" in
  reset)
    echo forcing low power profile
    full_power
    low_power
  ;;
  low)
    echo setting low power profile
    low_power
  ;;
  medium)
    echo setting medium power profile
    medium_power
  ;;
  full)
    echo setting high power profile
    full_power
  ;;
  *)
    echo "Usage: powersave.sh {reset|low|medium|full}" >&2
    exit 2
  ;;
esac
