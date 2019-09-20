#!/bin/bash

# Copyright (C) 2018-2019 IoT.bzh
# Authors:
#    Stephane Desneux <stephane.desneux@iot.bzh>
#    Ronan Le Martret <ronan.lemartret@iot.bzh>
# Released under the Apache 2.0 license

detect_raspberry() {
	local rpimodel=$(readkey /sys/firmware/devicetree/base/model)
	[[ ! "$rpimodel" =~ ^Raspberry ]] && return 0;
	info "Raspberry PI family detected."

	local -A keys
	
	# soc information
	keys[soc_vendor]="Raspberry"
	keys[soc_family]="unknown"

	keys[soc_id]="unknown"

	keys[soc_name]="unknown"
	keys[cpu_cache_kb]="unknown"
	keys[gpu_name]=$(readkey /sys/firmware/devicetree/base/soc/gpu/compatible | cut -f 2- -d',')
	keys[soc_revision]="unknown"

	# detect cpu
	keys[cpu_freq_mhz]=$(readkey /sys/devices/system/cpu/cpufreq/policy0/cpuinfo_max_freq)
	if [ ${keys[cpu_freq_mhz]} != "unknown" ]
	then keys[cpu_freq_mhz]=$((${keys[cpu_freq_mhz]}/1000))
	fi

	local k1=$(grep OF_COMPATIBLE_0 /sys/devices/system/cpu/cpu0/uevent | cut -f2 -d',')
	keys[cpu_compatibility]="$k1"

	# detect board
	models=( $(tr '\0' '\n' </sys/firmware/devicetree/base/compatible | while IFS=',' read vendor model; do echo $model; done) )
	keys[board_model]=$(IFS=- ; echo "${models[*]}")
	
	for x in ${!keys[@]}; do
		addkey $x "${keys[$x]}"
	done
}

detect_raspberry
