# platform-runtime-tools

Collection of tools for hardware detection, devices settings, custom boot options, hotplug handling ...

## Generated hardware info

### Renesas H3

```
# cat /etc/platform-info/hardware
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
## Generated devices info

### Renesas Kingfisher + H3

```
# cat /etc/platform-info/devices
HW_BLUETOOTH_DEVICES="hci0"
HW_ETHERNET_DEVICES="dummy0 eth0"
HW_CAN_DEVICES="can0 can1"
HW_WIFI_DEVICES="wlan0"
```
