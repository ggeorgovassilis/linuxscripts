#!/bin/sh
user=`whoami`

if [ "$user" != "root" ]; then 
    echo Re-running as root
    sudo $0 $1
    exit 0
fi

echo Running powersave
COMMAND=$1
DIRECTION="unload"

# the IFS variable handles how for loops deal with spaces in filenames
SAVEIFS=$IFS
IFS='
'


switch_module () {
case $DIRECTION in
	"unload")
	echo unloading module $1
	rmmod -f $1 || echo cannot remove $1
	;;
	"load")
	insmod $1 || echo cannot insert $1
	;;
	esac
}

switch_service () {
	case $DIRECTION in
	"unload")
	/etc/init.d/$1 stop || echo cannot stop $1
	;;
	"load")
	/etc/init.d/$1 start || echo cannot start $1
	;;
	esac
}

make_cpus_sleep () {
# set the powersave governor over the ondemand governor
	for i in `find /sys/devices/system/cpu/*/cpufreq/scaling_governor`; do echo powersave > "$i"; done;
# fix frequency at 1.2 GHz (lowest available)
	for i in `find /sys/devices/system/cpu/*/cpufreq/scaling_min_freq`; do echo 1200000 > "$i"; done;
	for i in `find /sys/devices/system/cpu/*/cpufreq/scaling_max_freq`; do echo 1200000 > "$i"; done;
}

disable_cpu () {
	echo 0 > /sys/devices/system/cpu/cpu$1/online
}

increase_fs_write_cache_timeout () {
	echo 1500 > /proc/sys/vm/dirty_writeback_centisecs
}

enable_pm_on_pci () {
	find /sys/devices/pci* -path "*power/control" -exec bash -c "echo auto > '{}'" \;
	for i in `find /sys/bus/pci/devices/*/power/control`; do echo auto > "$i"; done
	for i in `find /sys/bus/i2c/devices/*/power/control`; do echo auto > "$i"; done
# Override PCIE power management
	echo powersave > /sys/module/pcie_aspm/parameters/policy
}

increase_audio_buffers () {
	for i in `find /proc/asound/* -path */prealloc`; do echo 4096 > "$i"; done;
}

disable_nmi_watchdog () {
	echo 0 > /proc/sys/kernel/nmi_watchdog
}

enable_intel_audio_pm () {
	echo 1 > /sys/module/snd_hda_intel/parameters/power_save
}

disable_bluetooth () {
	rfkill block bluetooth
}

enable_cpu_pm () {
	for i in `find /sys/devices/system/cpu/*/cpufreq/scaling_governor`; do echo ondemand > "$i"; done;
	for i in `find /sys/devices/*/power/control`; do echo auto > "$i"; done;
}

enable_usb_pm () {
# Powersaving for USB. This disables some USB ports
	for i in `find /sys | grep \/power/level$`; do echo auto > "$i"; done;
	for i in `find /sys | grep \/autosuspend$`; do echo 2 > "$i"; done;
}


enable_sata_pm () {
	for i in `find /sys | grep \/link_power_management_policy$`; do echo min_power > "$i"; done
}

enable_pm_for_everything () {
 	for i in `find /sys -nowarn | grep /control$`
	do
		echo auto > "$i"
	done
}

disable_graphics_ports () {
# some graphics tweaks - might or might not work depending whether radeon or fglrx driver is used
#	echo low > /sys/class/drm/card0/device/power_profile
#	echo profile > /sys/class/drm/card0/device/power_method

# disable external graphics ports
	xrandr --output VGA1 --off
	xrandr --output HDMI1 --off
	xrandr --output DP1 --off
	xrandr --output VIRTUAL1 --off
}

enable_laptop_mode_tools () {
	echo 5 > /proc/sys/vm/laptop_mode
}

hdd_pm () {
#Make HDD park heads
# I've got an SSD, so...
	hdparm -B 1 /dev/sda
}

silence_audio () {
	amixer set Mic 0% mute
	amixer set Capture 0% mute
	amixer set "Internal Mic" 0% mute
}

wlan_pm () {
	iwconfig wlan0 rate 11M retry 24 txpower auto rts 250 frag 512 power on
}


tame_syndaemon () {
	killall syndaemon	
	(syndaemon -i 2.0 -K -R -t -m 500)&
}

disable_ethernet () {
# Disable wake on lan for LAN
	ethtool -s eth0 wol d || echo not setting wol on eth0
	ifconfig eth0 down
}

disable_usb_polling () {
	(udisks --inhibit-all-polling)&
}

case $COMMAND in
	light|on|extra)
	increase_fs_write_cache_timeout
	enable_pm_on_pci
	increase_audio_buffers
	disable_nmi_watchdog
	enable_intel_audio_pm
	disable_bluetooth
	enable_cpu_pm
	enable_usb_pm
	enable_sata_pm
	enable_pm_for_everything
	disable_graphics_ports
	enable_laptop_mode_tools
	hdd_pm
	silence_audio
	wlan_pm
	disable_ethernet
;;
esac

case $COMMAND in
	on|extra)

	tame_syndaemon
	switch_service mysql
	switch_service ntp
	switch_service cron
	switch_service anacron
	switch_service cups

	switch_module btusb
	switch_module bluetooth
	switch_module parport_pc
	switch_module joydev
	switch_module lp
	switch_module ppdev
	switch_module parport
	switch_module serio_raw
	switch_module snd_hda_codec_hdmi
	switch_module snd_seq_midi
	switch_module snd_rawmidi
	switch_module alx

	make_cpus_sleep
	disable_cpu 2
	disable_cpu 3
	disable_cpu 4
	disable_cpu 5
	disable_cpu 6
	disable_cpu 7
	
	;;
esac

case $COMMAND in
extra)

/home/george/bin/powersave on
# stop irqbalance
	switch_service irqbalance

# stop pulseaudio
	switch_service pulseaudio

#disable USB polling
	disable_usb_polling

#disable update notifier
	killall update-notifier
	killall ssh-agent

	disable_cpu 1

# network
	switch_service winbind
	switch_service network-manager

#disable modules
	switch_module hp-wmi
	switch_module r8169
	switch_module vboxpci
	switch_module vboxnetadp
	switch_module vboxnetflt
	switch_module vboxdrv 
	switch_module snd_hda_codec_hdmi
	switch_module mei
	switch_module rt2800pci
	switch_module rt2800lib
	switch_module rt2x00pci
	switch_module rt2x00lib
	switch_module mac80211
	switch_module cfg80211
	switch_module uas
	switch_module wmi
	switch_module msr
	switch_module video
;;

# I don't use the 'off' option ever so it's neither tested nor supported
off)

DIRECTION="load"

# reset filesystem write cache timeout
	echo 500 > /proc/sys/vm/dirty_writeback_centisecs

# Reset pulseaudio buffers
	for i in `find /proc/asound/* -path */prealloc`; do echo 64 > $i; done;

# Enable power management on all PCI devices
	find /sys/devices/pci* -path "*power/control" -exec bash -c "echo off > '{}'" \;

# Enable power aware CPU scheduler
	echo 0 > /sys/devices/system/cpu/sched_mc_power_savings

# Enable WLAN power management
	iwconfig wlan0 power off
	iwconfig wlan0 txpower auto

# Enable Intel audio power management
	echo 0 > /sys/module/snd_hda_intel/parameters/power_save

# Enable SATA power management
	for i in /sys/class/scsi_host/host*/link_power_management_policy; do echo max_performance > $i; done

# Enable laptop mode tools
	echo 1 > /proc/sys/vm/laptop_mode

# Override PCIE power management
	echo performance > /sys/module/pcie_aspm/parameters/policy

# Disable wake on lan for LAN
	ethtool -s eth0 wol u || echo not setting wol on eth0

# start mysql
	switch_service mysql

# start ntp
	switch_service ntp

# start cron and anacron
	switch_service cron
	switch_service anacron

# start cups
	switch_service cups

# harddisk
	hdparm -B254 /dev/sda

# restart touchpad deamon
	(/usr/bin/syndaemon -R -d)&


# some radeon tweaks
	echo auto > /sys/class/drm/card0/device/power_profile
	echo profile > /sys/class/drm/card0/device/power_method
	xrandr --output VGA-0 --on
	xrandr --output HDMI-0 --on
	xrandr --output VGA-0 --on
	xrandr --output HDMI-0 --on

#enable bluetooth
	hciconfig hci0 up || echo skip bluetooth

# network
	switch_service winbind
	switch_service network-manager

	switch_module btusb
	switch_module bluetooth
	switch_module hp-wmi
	switch_module parport_pc
	switch_module joydev
	switch_module lp
	switch_module ppdev
	switch_module parport
#switch_module ums_realtek
#switch_module usb_storage
	switch_module r8169
	switch_module vboxpci
	switch_module vboxnetadp
	switch_module vboxnetflt
	switch_module vboxdrv 
	switch_module snd_hda_codec_hdmi
	switch_module mei
	switch_module rt2800pci
	switch_module rt2800lib
	switch_module rt2x00pci
	switch_module rt2x00lib
	switch_module mac80211
	switch_module cfg80211
	switch_module uas
	switch_module wmi
	switch_module msr
	switch_module video
;;
esac

IFS=$SAVEIFS
