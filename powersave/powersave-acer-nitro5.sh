#!/bin/bash

# Common functions
LOW_FRQ=900Mhz
MED_FRQ=1200MHz
MAX_FRQ=4GHz

ETH=enp7s0
MAX_CPU=9

powertop_defaults()
{
powertop --auto-tune
# nvme disappears without this
echo 0 > /sys/module/nvme_core/parameters/default_ps_max_latency_us
}

cpu_on()
{
index=$1
on_cpus=$index
off_cpus=$((on_cpus+1))
echo on_cpus $on_cpus off_cpus $off_cpus

for cpu in /sys/devices/system/cpu/cpu[0-$on_cpus]*/online; do
  echo 1 >"$cpu"
done

for cpu in /sys/devices/system/cpu/cpu[$off_cpus-$MAX_CPU]*/online; do
  echo 0 >"$cpu"
done
}

cpu_slow(){
echo off > /sys/devices/system/cpu/smt/control
cpupower set --perf-bias 15
cpupower frequency-set --max $LOW_FRQ

cpu_on 3
}


ethernet_off()
{
ifconfig enp7s0 down
ip link set "$ETH" down
}

ethernet_on(){
ip link set "$ETH" up
ifconfig enp7s0 up
}

bluetooth_off()
{
rfkill block bluetooth
rmmod btusb
rmmod acer_wmi
}

gpu_slow()
{
echo 350 > /sys/class/drm/card0/gt_max_freq_mhz   
echo 350 > /sys/class/drm/card0/gt_boost_freq_mhz 
# lspci -vv to find pci device id
# nvidia graphics
echo 1 > /sys/bus/pci/devices/0000:01:00.0/remove
# nvidia audio
echo 1 > /sys/bus/pci/devices/0000:01:00.1/remove
}

##################################################
# power profiles
low_power()
{
powertop_defaults
ethernet_off
#bluetooth_off
cpu_slow
gpu_slow
}


medium_power()
{
powertop_defaults

for x in /sys/devices/system/cpu/cpu[0-9]*/online; do
  echo 1 >"$x"
done

#for x in /sys/devices/system/cpu/cpu[3-9]*/online; do
#  echo 0 >"$x"
#done

cpupower frequency-set --max "$MED_FRQ"

echo 350 > /sys/class/drm/card0/gt_max_freq_mhz   
echo 350 > /sys/class/drm/card0/gt_boost_freq_mhz
ethernet_on
}




full_power()
{
echo on > /sys/devices/system/cpu/smt/control
cpupower frequency-set --max $MAX_FRQ
cpupower set --perf-bias 5
modprobe btusb
rfkill unblock bluetooth
ethernet_on

echo 800 > /sys/class/drm/card0/gt_max_freq_mhz   
echo 800 > /sys/class/drm/card0/gt_boost_freq_mhz 
cpu_on $MAX_CPU

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

