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

The files are spreaded like this:

* bin/ : main tools (pr-\*)
* etc/pr-tools/ : configuration files for pr-registry
* lib/systemd/system: systemd services
* libexec/prtools/: scriptlets run by detection or customization tools

<!-- ----------------------------------------------------- -->
## Detection tool: pr-detect

pr-detect is the script called in detection phases.

```
Usage: pr-detect <option>

Options:
	-h|--help|--fullhelp: get help
	-V|--version: get version
	-d|--debug: enable debug
	-s|--step <name|dir>: set detection step by name or by directory (mandatory)
		If a name is given, a folder named /usr/libexec/platform-runtime-tools/detect/<name>
		is used for detection scripts.
		If a directory is given, it's used directly.
		Common names are: 'core','devices'
	-o|--output-file <file>: generate output file in SHELL format (default: stdout)
	-j|--json-file <file>: generate output file in JSON format (optional)
```

It's typically called with the following arguments from systemd services to generate core information in /etc/platform-info:

```
...
ExecStart=/usr/bin/pr-detect --step=core --output-file=/etc/platform-info/core --json-file=/etc/platform-info/core.json
...
```

### Adding a detection script

Detection scripts are run sequentially from /usr/libexec/platform-runtime-tools/detect/\<step_name\> or from a folder passed as a step name.

File hierarchy example:

```
/usr/libexec/platform-runtime-tools/detect/core
|-- 10_generic_hardware.sh
|-- 50_intel.sh
|-- 50_raspberry-pi.sh
`-- 50_renesas-rcar.sh
```

A scriptlet can have any name but it's recommended to add a prefix to guarantee the execution order.

Each scriptlet is sourced by `pr-detect` and is responsible for setting the keys using a helper function 'addkey' provided by `pr-detect` (see below).

**IMPORTANT**: A scriptlet is responsible to detect if it should be run or not depending
on the runtime environment. For example, the scriptlet 50_renesas-rcar.sh
will be run even when booting on an Intel board. Usually, the first steps in the scriptlet check for execution conditions.

Code example:

```
#!/bin/bash

detect_renesas() {
	[[ ! -f /sys/devices/soc0/family ]] && return 0;
	[[ ! "$(cat /sys/devices/soc0/family)" =~ ^R-Car ]] && return 0;
	info "R-Car SoC family detected."
    
    # continue detection
    # ...
}

detect_renesas
```
Here, the script is neutral if execution conditions are not met.

A special feature has been added for first boot scriptlets: if the scriptlet name matches the regex ^[0-9]+(FB|firstboot)_ , it's considered as a firstboot scriptlet and will be removed after execution. This way, it's guaranteed that the scriptlet only executes once.

Available helper functions are:

* info \<message\> : log an informational message on stderr
* warning \<message\> : log a warning message on stderr and continue
* error \<message\> : log an error message on stderr and continue
* fatal \<message\> : log an error message **and exit definitely from `pr-detect`** (WARNING: other scriptlets won't be executed and results won't be produced)
* debug \<message\> : log a debug message (only when `pr-detect` is invoked with debug option -d)
* addkey \<key\> \<arg1\> [arg2 ... argn] : create an entry in the associative array used as the final result of `pr-detect`. If multiple args are given, they are concatenated with spaces

    Example:
    ```
    addkey soc_vendor Renesas
    addkey some_comment This is a comment
    ```
    produces the following outputs:
    
    * Shell mode:
    
        ```shell
        SOC_VENDOR=Renesas
        SOME_COMMENT="This is a comment"
        ```
    
    * JSON mode:
    
        ```json
        {
            "soc_vendor":"Renesas",
            "some_comment":"This is a comment"
        }
        ```
* readkey \<filename\> : outputs the content of a file or "unknown" if it doesn't exist or is empty. Useful for reading in /sys or /proc.

    Example:
    ```bash
    family=$(readkey /sys/devices/soc0/family)
    echo $family
    ```


### Generated hardware info

#### Common Keys

The following keys are generated by the detection scripts in step 'core':

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

#### Optional Keys

To be defined.

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
## Customization tool: pr-customize

The tool `pr-customize` is used to adjust the runtime configuration of the system after each detection phase. It's similar to `pr-detect` but doesn't produce any result: it just runs some scriptlets at the right time to adjust the platform configuration.

(TODO: fill topics)

* pr-customize tool description
* steps (core, devices, ...)
* scripts location
* firstboot
* example scriptlet

<!-- ----------------------------------------------------- -->
## Helper tool: pr-registry

The tool `pr-registry` is a helper to query a "registry" (a list of variables) where entries are defined conditionnaly: the values may be defined or not depending on hardware architecture, platform vendor and board model.

### Usage

```
Usage: pr-registry [options] [<key>]
Version: 1.0.0

pr-registry retrieves and outputs the values for the requested configuration key.

Options:
   -h|--help|--fullhelp: get help
   -V|--version: get version
   -d|--debug: enable debug
   -c|--config <file>: extra configuration file to load (may be used multiple times)
   -a|--all: dump the full registry (that can be used like this: pr-registry -a | . /dev/stdin)
   -k|--keys: dump all defined keys
   ```

### Configuration sources and syntax

Registry values are set by parsing different sources:

* configuration file: default is /etc/pr-tools/registry.conf
* configuration folders containing fragments: default is /etc/pr-tools/registry.conf.d . This is useful to deploy a configuration fragment associated to a package.
* kernel command line
* extra files passed with option -c

A configuration file is a plain text file where:

* comments start with '#' until the end of line (shell style)
* empty lines (or only with spaces and tabs) are considerd as comments
* registry entry name is composed of three parts separated by a dot '.':

  * a **\<prefix\>** (example: 'agl')

    The prefix is useful when the registry entry has to be defined in the kernel command line. It's easy to identify if an argument acts as a runtime switch or not.

  * a **\<domain\>** which defines when the variable is set. It can be:

    * a CPU architecture: 'aarch64','x86_64','arm' ...
    * a SoC vendor: 'renesas', 'intel' ...
    * a board name: 'kingfisher-h3ulcb-r8a7795', 'minnowboard-turbot' ...
    * 'common' litterally, meaning that the variable is always defined (no condition on architecture, vendor or board model)

    Architectures, vendors and board names are the ones set by core detection scripts (see `pr-detect`)

  * a **\<name\>** (one or more alphanumeric characters + underscore - no space) used to query the registry.

* defining a registry entry is done by writing:

  * for values without spaces:

    \<prefix\>.\<domain\>.\<name\>=\<value\>

  * for values with spaces:

    \<prefix\>.\<domain\>.\<name\>="\<value\>"

  * for boolean values:

    \<prefix\>.\<domain\>.\<name\>


Generaly speaking, writing 

```
<prefix>.<domain>.<name>=<value>
```
means:


> "When running on platform '\<prefix\>',
> if architecture or vendor or board is '\<domain\>' or if '\<domain\>' is 'common' then
> define the variable named '\<name\>' with value '\<value\>'.
> Otherwise, the variable is undefined."

So writing:

```
agl.common.debug=true
```

defines the variable 'debug' with value 'true' in any case (=any architecture/vendor/board)

And writing:
```
agl.aarch64.aarch64_detected=1
```

defines the variable 'aarch64_detected' with value '1' only if the current platform has a CPU running with architecture 'aarch64'. When queried on another platform, the variable will be seen as empty.

### Why parsing the kernel command line?

The syntax is also usable on kernel command line. In this case, only the arguments beginning with the predefined prefix ('agl' by default) are parsed by `pr-registry`.

For example:

```
console=ttySC0,115200 root=/dev/ram0 ... agl.aarch64.enable_feature_foo=1 agl.renesas.kf_m03_bug_workaround=1 ...
```

In the above example, the variable 'agl.renesas.kf_m03_bug_workaround' is set manually in the boot loader to instruct a customization scriptlet to do whatever is needed to add workarounds against an hypothetical bug. But only the owners of the buggy hardware will be instructed to set the workaround flag in the kernel command line. Other people (with non buggy hardware) won't define the value. As a result, the same image built for all kingfisher boards will run correctly and the workaround will be applied only when running on the buggy boards.

This is also a way to adjust the runtime behaviour through platform/runtime specific settings (opposed to image-specific ones, which are generic by nature). Possibilities are limitless:

* disable/enable some devices
* disable/enable some services
* change global log level
* enable diagnostics
* add some tweaks
* ...

### Basic usage

Let's boot AGL on a Renesas H3ULCB board, with Kingfisher baseboard installed.

After the 'core' detection phase by `pr-detect`, /etc/platform-info/core contains:

```
...
HW_CPU_ARCH="aarch64"
...
HW_SOC_VENDOR="renesas"
...
HW_BOARD_MODEL="kingfisher-h3ulcb-r8a7795"
...
```

Let's adjust manually the registry entries in /etc/pr-tools/registry.conf:

```
agl.common.verbose
agl.common.debug=true
agl.common.root_password=fbgUx1ap3tCTPBT2
agl.common.binder_loglevel=4
agl.common.welcome_message="Hi there, you're welcome !!!"

# to restrict to a given architecture:
agl.aarch64.enable_option_foo=true
agl.x86_64.disable_option_bar=true

# to restrict to a given vendor:
agl.renesas.e3_emulation=true
agl.intel.xeon_for_embedded=true
agl.amd.r1000=true

# to restrict to a given board:
agl.kingfisher-h3ulcb-r8a7795.btwilink=off
agl.minnowboard-turbot.builtin_audio=off
```

Then, let's call `pr-registry` for some 'common' values. This gives the same results for any architecture/vendor/board (this is the goal of the 'common' domain!):

```
# pr-registry verbose
true
# pr-registry root_password
fbgUx1ap3tCTPBT2
```

Then, query some architecture-specific variables:

```
# pr-registry enable_option_foo
true
# pr-registry disable_option_bar
#                                        <= empty
```

The first variable 'enable_option_foo' is set because current architecture is 'aarch64'. The second variable 'disable_option_bar' is empty because it's only defined for architecture 'x86_64'.

Similar results are obtained with vendor and board models:

```
# pr-registry e3_emulation
true
# pr-registry xeon_for_embedded
#                                        <= empty
# pr-registry btwilink
off
# pr-registry builtin_audio
#                                        <= empty 
```

### Dumping registry content

Additionnaly to querying the registry, it's also possible to dump its content. For this, use options '-a' to dump everything or '-k' to dump all keys.

If we take the same configuration as previously, this gives:

```
# pr-registry -a
binder_loglevel='4'
btwilink='off'
debug='true'
e3_emulation='true'
enable_option_foo='true'
root_password='fbgUx1ap3tCTPBT2'
verbose='true'
welcome_message='Hi there, you'\''re welcome !!!'
```

Note that the output of 'pr-registry -a' is compatible with shell syntax and can be sourced in a shell environment to access registry variables easily:

In bash:
```
# source <(pr-registry -a)
# echo $root_password
fbgUx1ap3tCTPBT2
```

In sh:
```
# eval "$(pr-registry -a)"
# echo $root_password
fbgUx1ap3tCTPBT2
```

And the list of defined keys:

```
# pr-registry -k
binder_loglevel
btwilink
debug
e3_emulation
enable_option_foo
root_password
verbose
welcome_message
```

### Using pr-registry in scriptlets

The main usage of `pr-registry` is to query the registry to retrieve a variable value.

In conjunction with `pr-customize`, this can be used to make integrators life easier.

For example, let's write a scriptlet to be triggered in 'core' step (see `pr-detect`). The goal of the scriptlet is to enable or disable a kernel module 'btwilink' based on runtime detection and registry settings.

In that case, `pr-registry` can be used to make detection easier. The scriptlet would look like this:

```bash
#!/bin/bash
v=$(pr-registry enable-btwilink)
case ${v,,} in
	1|true|on|yes)
		echo "$BASH_SOURCE: enabling btwilink module" >&2
		rm -f /etc/modprobe.d/btwilink-disable.conf
		;;
	*)
		echo "$BASH_SOURCE: disabling btwilink module" >&2
		lsmod | grep -q  btwilink && rmmod btwilink
		echo "install btwilink /bin/false" > /etc/modprobe.d/btwilink-disable.conf
		;;
esac
```
