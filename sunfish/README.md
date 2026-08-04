# Sunfish firmware builds

Run the local build helper from the repository root:

```sh
./sunfish/build.sh
```

By default it builds the `CUAV-7-Nano` bootloader and ArduSub firmware. Pass a
board name and, optionally, an artifact directory to override those defaults:

```sh
./sunfish/build.sh CUAVv5Nano /tmp/cuav-firmware
```

Artifacts are written to `sunfish/artifacts/<board>` by default. The script
builds a fresh bootloader, uses it to create the combined ArduSub HEX image, and
restores the checked-in bootloader binary when it exits.
