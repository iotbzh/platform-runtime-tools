# platform-runtime-tools (pr-tools)

Collection of tools for hardware detection, devices settings, custom boot options, hotplug handling ...

<!-- ----------------------------------------------------- -->
## Authors & License

Copyright (C) 2019 IoT.bzh

Authors:

* Stephane Desneux <stephane.desneux@iot.bzh>
* Ronan Le Martret <ronan.lemartret@iot.bzh>

Released under the [Apache 2.0 license](LICENSE).

<!-- ----------------------------------------------------- -->
## Introduction

### Background and objectives

Projects such as [AGL](https://automotivelinux.org) run on various hardware platforms and the same distribution image should run on multiple boards with different hardware configuration.

There's a need for detecting platform features at runtime:

* to save some build cycles (one image for multiple boards)
* to detect hardware details that are not known at build time
* to support hot-plugged devices

This repository contains the tools that can be used for:

* running detection scripts
* generating hardware information in a common way
* adjust runtime configuration of the system after the detection phase

The topic is covered by Jira ticket in AGL: [SPEC-720](https://jira.automotivelinux.org/browse/SPEC-720).

### General workflow

The first step is named 'core': the goal is to detect hardware details as early as possible in the system startup sequence: this allows to "react" to some hardware feature before having the full system set up. In particular, acting as early as possible allows to block or force kernel modules loading.

Then the second step is named 'devices': here, the goal is to detect devices and buses (=non fundamental hardware components) and enumerate the existing interfaces (e.g. bluetooth, ethernet, CAN, ...).

The systemd startup sequence is as follows:

* ...
* systemd-journald.service
* platform-core-detection.service
* platform-core-customize.service
* ...
* systemd-modules-load.service
* ...
* platform-devices-detection.service
* platform-devices-customize.service

<!-- ----------------------------------------------------- -->
## Building, installing

The project uses cmake.

To build and install, use following commands:

```bash
git clone https://github.com/iotbzh/platform-runtime-tools
cd platform-runtime-tools
mkdir build
cd build
cmake .. -DCMAKE_INSTALL_PREFIX=install
make install
```

This gives the following files in the install dir:

```bash
install
├── bin
│   ├── pr-customize
│   ├── pr-detect
│   └── pr-registry
├── etc
│   └── pr-tools
│       ├── registry.conf
│       └── registry.conf.d
├── lib
│   └── systemd
│       └── system
│           ├── platform-core-customize.service
│           ├── platform-core-detection.service
│           ├── platform-devices-customize.service
│           └── platform-devices-detection.service
└── libexec
    └── pr-tools
        ├── customize
        │   ├── core
        │   └── devices
        └── detect
            ├── core
            │   ├── 10_generic_hardware.sh
            │   ├── 30_aarch64.sh
            │   ├── 30_x86_64.sh
            │   ├── 50_intel.sh
            │   └── 50_renesas-rcar.sh
            └── devices
                └── 10_generic_device.sh
```

The files are spread like this:

* bin/ : main tools (pr-*)
* etc/pr-tools/ : configuiration scripts for pr-registry
* lib/systemd/system: systemd services
* libexec/prtools/: scriptlets run by detection or customization tools

<!-- ----------------------------------------------------- -->
## Detection tool: pr-detect

(TODO)

### Adding a detection script

(TODO)

### Generated hardware info

#### Common Keys

* board_model
* soc_id
* soc_name
* soc_vendor
* soc_family
* soc_revision
* gpu_name
* cpu_freq_mhz
* cpu_compatibility
* cpu_cache_kb

(TODO)

#### Optional Keys

(TODO)

#### Core output example for Renesas H3 with Kingfisher board

```bash
# cat /etc/platform-info/core
HW_CPU_COUNT=8
HW_MEMORY_TOTAL_MB=3776
HW_SOC_FAMILY="R-Car Gen3"
HW_CPU_ARCH="aarch64"
HW_SOC_NAME="H3"
HW_CPU_FREQ_MHZ=1500
HW_SOC_ID="r8a7795"
HW_CPU_COMPATIBILITY="cortex-a57 armv8"
HW_GPU_NAME="IMG PowerVR Series6XT GX6650"
HW_CPU_CACHE_KB=3044
HW_SOC_REVISION="ES2.0"
HW_SOC_VENDOR="renesas"
HW_BOARD_MODEL="kingfisher-h3ulcb-r8a7795"
```
#### Core output example for Raspberry PI 3 board

```bash
# cat /etc/platform-info/core
HW_CPU_COUNT=4
HW_MEMORY_TOTAL_MB=873
HW_SOC_FAMILY="unknown"
HW_CPU_ARCH="armv7l"
HW_SOC_NAME="unknown"
HW_CPU_FREQ_MHZ=1200
HW_SOC_ID="bcm-xxxx"
HW_CPU_COMPATIBILITY="cortex-a53"
HW_GPU_NAME="bcm2835-vc4"
HW_CPU_CACHE_KB="unknown"
HW_SOC_REVISION="unknown"
HW_BOARD_MODEL="3-model-b-bcm2837"
HW_SOC_VENDOR="raspberry"
```

### Generated devices info

### Devices output example for Renesas H3 with Kingfisher board

```bash
# cat /etc/platform-info/devices
HW_BLUETOOTH_DEVICES="hci0"
HW_ETHERNET_DEVICES="dummy0 eth0"
HW_CAN_DEVICES="can0 can1"
HW_WIFI_DEVICES="wlan0"
```

<!-- ----------------------------------------------------- -->
## Customization tools

(TODO: fill topics)

* pr-customize tool
* goal
* steps (core, devices, ...)
* scripts location
* firstboot
* example scriptlet

<!-- ----------------------------------------------------- -->
## Helper (Registry) tools

(TODO: fill topics)

* pr-registry tool
* goal
* configuration files/dir/kernel command line/extra files
