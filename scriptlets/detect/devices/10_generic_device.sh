#!/bin/bash

# Copyright (C) 2018-2019 IoT.bzh
# Authors:
#    Stephane Desneux <stephane.desneux@iot.bzh>
#    Ronan Le Martret <ronan.lemartret@iot.bzh>
# Released under the Apache 2.0 license

detect_netifaces() {
	[[ ! -d /sys/class/net ]] && { error "Unable to find /sys/class/net"; return 1; }

	local can=()
	local eth=()
	local wifi=()

	for x in $(ls -d /sys/class/net/* 2>/dev/null); do
		iface=$(basename $x)
		type=$(cat $x/type)

		case $type in
			1)
				# ethernet/bridge/wlan/...
				if [[ -d $x/wireless ]]; then
					wifi+=($iface)
				else
					eth+=($iface)
				fi
				;;
			280)
				# can
				can+=($iface)
				;;
			772)
				# localhost
				;;
			65534)
				# tun
				;;
			*)
				;;
		esac
	done

	addkey can_devices "${can[@]}"
	addkey ethernet_devices "${eth[@]}"
	addkey wifi_devices "${wifi[@]}"
}

detect_bluetooth() {
	local bt=()
	for x in $(ls -d /sys/class/bluetooth/* 2>/dev/null); do
		bt+=($(basename $x))
	done
	addkey bluetooth_devices "${bt[@]}"
}

detect_netifaces
detect_bluetooth

