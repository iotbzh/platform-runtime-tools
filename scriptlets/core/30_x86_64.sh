#!/bin/bash

# Copyright (C) 2018-2019 IoT.bzh
# Authors:
#    Stephane Desneux <stephane.desneux@iot.bzh>
#    Ronan Le Martret <ronan.lemartret@iot.bzh>
# Released under the Apache 2.0 license

detect_arch() {
	local -A keys

	keys[cpu_arch]="unknown"
	[[ "$(grep MODALIAS /sys/devices/system/cpu/cpu0/uevent)" =~ :type:([^:]+):.*$ ]] && {
		keys[cpu_arch]=$(uname -i)
	}

	addkey cpu_arch "${keys[cpu_arch]}"

	#do specific arch detection here
}

detect_arch
