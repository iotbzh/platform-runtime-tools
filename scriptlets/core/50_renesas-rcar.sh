#!/bin/bash

# Copyright (C) 2018-2019 
#		Stephane Desneux <stephane.desneux@iot.bzh>
#		Ronan Le Martret <ronan.lemartret@iot.bzh>
# Released under the Apache 2.0 license

detect_renesas() {
	[[ ! "$(cat /sys/devices/soc0/family)" =~ ^R-Car ]] && return 0;
	info "R-Car SoC family detected."

	# from https://elinux.org/R-Car
	# 
	# "H" - Premium/High end
	#    H1 - R8A7779
	#    H2 - R8A7790 	
	#    H3 - R8A7795 (or R8J7795)
	# "M" - Mid range
	#    M1A - R8A7778
	#    M2-W - R8A7791
	#    M2-N - R8A7793
	#    M3-W - R8A77960
	#    M3-N - R8A77965
	# "E" - Entry class
	#    E2 - R8A7794
	#    E3 - R8A77990
	# "V" - ADAS
	#    V2H - R8A7792
	#    V3M - R8A77970
	#    V3H - R8A77980

	local -A keys
	
	# soc information
	keys[soc_vendor]="Renesas"
	keys[soc_family]=$(readkey /sys/devices/soc0/family)

	keys[soc_id]=$(readkey /sys/devices/soc0/soc_id)
	keys[soc_id]=${keys[soc_id],,}

	keys[soc_name]="unknown"
	keys[cpu_cache_kb]="unknown"
	keys[gpu_name]="unknown"
	case ${keys[soc_id]} in
		r8a7779)			keys[soc_name]="H1"   ;;
		r8a7790)			keys[soc_name]="H2"   ;;
		r8a7795|r8j7795)	keys[soc_name]="H3"; keys[cpu_cache_kb]=3044; keys[gpu_name]="IMG PowerVR Series6XT GX6650";   ;;
		r8a7778)			keys[soc_name]="M1A"  ;;
		r8a7791)			keys[soc_name]="M2-W" ;;
		r8a7793)			keys[soc_name]="M2-N" ;;
		r8a7796)			keys[soc_name]="M3"; keys[cpu_cache_kb]=1952; keys[gpu_name]="IMG PowerVR Series6XT GX6250";   ;;
		r8a77960)			keys[soc_name]="M3-W" ;;
		r8a77965)			keys[soc_name]="M3-N" ;;
		r8a7794)			keys[soc_name]="E2"   ;;
		r8a77990)			keys[soc_name]="E3"; keys[cpu_cache_kb]=384; keys[gpu_name]="IMG PowerVR Series8XE GE8300";   ;;
		r8a7792)			keys[soc_name]="V2H"  ;;
		r8a77970)			keys[soc_name]="V3M"  ;;
		r8a77980)			keys[soc_name]="V3H"  ;;
		*)
			error "Unknown SOC ID - couldn't determine soc name"
			;;
	esac

	keys[soc_revision]=$(readkey /sys/devices/soc0/revision)

	# detect cpu
	keys[cpu_arch]="unknown"
	[[ "$(grep MODALIAS /sys/devices/system/cpu/cpu0/uevent)" =~ :type:([^:]+):.*$ ]] && {
		keys[cpu_arch]=${BASH_REMATCH[1]}
	}
	keys[cpu_freq_mhz]=$(readkey /sys/devices/system/cpu/cpufreq/policy0/cpuinfo_max_freq)
	if [ ${keys[cpu_freq_mhz]} != "unknown" ]
	then keys[cpu_freq_mhz]=$((${keys[cpu_freq_mhz]}/1000))
	fi

	local k1=$(grep OF_COMPATIBLE_0 /sys/devices/system/cpu/cpu0/uevent | cut -f2 -d',')
	local k2=$(grep OF_COMPATIBLE_1 /sys/devices/system/cpu/cpu0/uevent | cut -f2 -d',')
	keys[cpu_compatibility]="$k1 $k2"

	# detect board
	models=( $(tr '\0' '\n' </sys/firmware/devicetree/base/compatible | while IFS=',' read vendor model; do echo $model; done) )
	keys[board_model]=$(IFS=- ; echo "${models[*]}")
	
	for x in ${!keys[@]}; do
		addkey $x "${keys[$x]}"
	done
}

detect_renesas
