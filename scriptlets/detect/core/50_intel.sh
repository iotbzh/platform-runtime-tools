#!/bin/bash

# Copyright (C) 2018-2019 IoT.bzh
# Authors:
#    Stephane Desneux <stephane.desneux@iot.bzh>
#    Ronan Le Martret <ronan.lemartret@iot.bzh>
# Released under the Apache 2.0 license

detect_intel() {
	[[ ! "$(cat /proc/cpuinfo | grep vendor_id -m1 | grep Intel)" ]] && return 0;
	info "Intel CPU detected."

	local -A keys
	
	# soc information
	keys[soc_vendor]="Intel"
	keys[soc_family]=$(dmidecode --type processor | grep -m1 Family | awk -F": " '{print $2}')
	keys[soc_id]=$(cat /proc/cpuinfo | grep name -m1 | sed -e 's/.*(TM) \(.*\)@.*/\1/' | sed 's/CPU//g' | sed 's/ //g')
	keys[soc_name]="${keys[soc_vendor]} ${keys[soc_family]} ${keys[soc_id]}"
	keys[soc_revision]=$(cat /proc/cpuinfo | grep -m1 "stepping" | awk -F": " '{print $2}')

	# cpu information
	keys[cpu_compatibility]="unknown"
	keys[cpu_freq_mhz]=$(dmidecode --type processor | grep -m1 "Max Speed" | awk -F": " '{print $2}' | awk '{print $1;}')
	#On Intel recent arch, L1 and L2 are per CPU core and L3 is optionnal and shared by all core.
	CPU_COUNT=$(getconf _NPROCESSORS_CONF)
	CPU_CACHE_L1=$(readkey /sys/devices/system/cpu/cpu0/cache/index1/size)
	CPU_CACHE_L1=${CPU_CACHE_L1%?}
	CPU_CACHE_L2=$(readkey /sys/devices/system/cpu/cpu0/cache/index2/size)
	CPU_CACHE_L2=${CPU_CACHE_L2%?}
	if [ -f /sys/devices/system/cpu/cpu0/cache/index3/size ]
	then
		CPU_CACHE_L3=$(readkey /sys/devices/system/cpu/cpu0/cache/index3/size)
		CPU_CACHE_L3=${CPU_CACHE_L3%?}
	else
		CPU_CACHE_L3=0
	fi
	keys[cpu_cache_kb]=$(($CPU_CACHE_L1*$CPU_COUNT+$CPU_CACHE_L2*$CPU_COUNT+$CPU_CACHE_L3))

	#gpu_information
	keys[gpu_name]="unknown"
	GPU_BUS=$(lspci | grep ' VGA ' | cut -d" " -f 1)
	if [ "$GPU_BUS" != "" ]
	then
		keys[gpu_name]=$(lspci -v -s $GPU_BUS | grep "Subsystem" | awk -F": " '{print $2}')
	fi

	for x in ${!keys[@]}; do
		addkey $x "${keys[$x]}"
	done
	
	#detect board model and add specific soc details
	case ${keys[soc_id]} in
		E3826)
			keys[board_model]="Minnowboard Turbot"	
			if lspci | grep -iq "i211"; then
				keys[board_model]=${keys[board_model]}" B Dual-Core"
			else
				keys[board_model]=${keys[board_model]}" A Dual-Core"
			fi

		E3845)
			keys[board_model]="Minnowboard Turbot B Quad-Core"		
			;;
		*)
			keys[board_model]="unknown"
			error "Unknown board model - couldn't determine board model"
			;;
	esac

	for x in ${!keys[@]}; do
		addkey $x "${keys[$x]}"
	done
}

detect_intel
