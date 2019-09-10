#!/bin/bash

# Copyright (C) 2018-2019 IoT.bzh
# Authors:
#    Stephane Desneux <stephane.desneux@iot.bzh>
#    Ronan Le Martret <ronan.lemartret@iot.bzh>
# Released under the Apache 2.0 license

# force $HW_CPU_ARCH $HW_SOC_VENDOR and $HW_BOARD_MODEL to be defined and lowercase
# these values are used by platform-hardware-config to run some scriptlets conditionnaly
# to arch, vendor and board model.
addkey "cpu_arch" "unknown"
addkey "soc_vendor" "unknown"
addkey "board_model" "unknown"

detect_cpu() {
	addkey "cpu_count" $(getconf _NPROCESSORS_CONF)
}

detect_memory() {
	# total mem in MB
	addkey "memory_total_mb" $(( $(getconf _PHYS_PAGES) * $(getconf PAGESIZE) / (1024*1024) ))
}

detect_cpu
detect_memory


