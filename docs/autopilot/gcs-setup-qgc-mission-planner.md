# Ground Control Station Setup for SITL

This guide covers connecting QGroundControl and Mission Planner to ArduSub SITL running in Docker.

## Overview

ArduSub SITL exposes MAVLink over TCP on port 5760. Both QGroundControl and Mission Planner support TCP connections, making them suitable for SITL development.

**Important**: Cockpit (BlueOS web UI) cannot connect directly to SITL because it requires MAVLink2REST as an intermediary, which is not included in the SITL container.

## QGroundControl Setup

### Installation

Download and install QGroundControl from: https://qgroundcontrol.com/

### Connecting to SITL

1. **Start SITL** (see [Quickstart Guide](sitl-quickstart-ardusub.md))

2. **Open QGroundControl**

3. **Add TCP Connection**:
   - Click the "Q" icon (top left)
   - Select "Application Settings"
   - Go to "Comm Links"
   - Click "Add" to create a new connection
   - Select "TCP" as the connection type
   - Enter:
     - **Name**: `SITL` (or any descriptive name)
     - **Server Address**: `127.0.0.1`
     - **Server Port**: `5760`
   - Click "OK" to save

4. **Connect**:
   - Click the connection dropdown (top toolbar)
   - Select your "SITL" connection
   - QGroundControl should connect and show vehicle telemetry

### Verifying Connection

Once connected, you should see:
- Vehicle status (armed/disarmed)
- GPS coordinates (from spawn location)
- Altitude/depth readings
- Vehicle orientation
- Real-time telemetry data

### Known Limitations

- **No MAVLink FTP**: QGroundControl does not support MAVLink FTP for file transfers
- **Serial Ports**: Serial port connections won't work with SITL (use TCP instead)

## Mission Planner Setup

### Installation

Download and install Mission Planner from: https://ardupilot.org/planner/

### Connecting to SITL

1. **Start SITL** (see [Quickstart Guide](sitl-quickstart-ardusub.md))

2. **Open Mission Planner**

3. **Add TCP Connection**:
   - Click the dropdown next to "Connect" (top right)
   - Select "TCP"
   - Enter:
     - **Host**: `127.0.0.1`
     - **Port**: `5760`
   - Click "Connect"

4. **Verify Connection**:
   - Mission Planner should show "Connected" status
   - You should see telemetry data in the Flight Data screen

### MAVLink FTP Access

Mission Planner includes MAVLink FTP support, which is useful for:
- Uploading Lua scripts to the autopilot
- Downloading telemetry logs from the SD card
- Managing files on the autopilot

**To access MAVLink FTP**:
1. Ensure Mission Planner is connected to SITL
2. Go to **Config/Tuning** → **MAVLink FTP**
3. Browse the file system
4. Upload/download files as needed

**Note**: MAVLink FTP is very slow (~32 kbps even on localhost). See [MAVLink FTP Guide](mavlink-ftp-and-files.md) for details.

## WSL (Windows Subsystem for Linux) Considerations

If you're running Docker in WSL and Mission Planner on Windows:

### Serial Ports Won't Work

Mission Planner running on Windows cannot access serial devices inside WSL. Use TCP connections instead (which work fine).

### TCP Connection Works

TCP connections from Windows applications to WSL-hosted containers work correctly:
- SITL container listens on `127.0.0.1:5760` inside WSL
- Windows applications can connect to `127.0.0.1:5760`
- Port forwarding happens automatically

### Troubleshooting WSL Connections

If you can't connect from Windows:

1. **Verify port mapping**: Ensure Docker port mapping is correct (`-p 5760:5760`)
2. **Check WSL networking**: Try connecting from within WSL first:
   ```bash
   telnet 127.0.0.1 5760
   ```
3. **Firewall**: Windows Firewall may block connections - check firewall settings

## Basic Operations

### Arming and Disarming

- **Arm**: Use the arm button in your GCS (typically requires throttle down and yaw right)
- **Disarm**: Use the disarm button (typically throttle down and yaw left)

**Note**: SITL may have different arming requirements than real hardware. Check parameters if arming fails.

### Manual Control

Both QGroundControl and Mission Planner support joystick/gamepad input for manual control:

- **QGroundControl**: Joystick support via Settings → General → Joystick
- **Mission Planner**: Joystick support via Flight Data → Joystick

**Known Issues**:
- Deadband on controllers may cause unresponsive controls
- Joystick mapping may differ from real vehicle configuration
- Some axes (like roll) may not be applicable to underwater vehicles

### Mission Planning

You can create and upload missions using either GCS:

- **QGroundControl**: Plan → Create mission
- **Mission Planner**: Flight Plan → Create waypoints

Missions can be uploaded to SITL just like real hardware.

## Connection Troubleshooting

### "No Heartbeat Packets Received"

This error means the GCS cannot communicate with SITL. Check:

1. **SITL is running**: Verify container is active (`docker ps`)
2. **Port is correct**: Ensure you're connecting to the right port (default: 5760)
3. **Host is correct**: Use `127.0.0.1` for localhost connections
4. **Model is valid**: SITL must start with a valid `MODEL` (see [Troubleshooting Guide](troubleshooting-sitl.md))

### Connection Times Out

- Verify SITL container logs for errors
- Check that port 5760 is actually listening:
  ```bash
  netstat -an | grep 5760
  ```
- Try restarting SITL container

### Connection Works But No Data

- Wait a few seconds for initial telemetry
- Check SITL logs (`/tmp/ardusub.log` inside container)
- Verify vehicle model is appropriate (some models may have limited telemetry)

## Why Not Cockpit/BlueOS UI?

Cockpit (the BlueOS web interface) requires MAVLink2REST as an intermediary:

- Cockpit talks HTTP/REST
- MAVLink2REST converts REST ↔ MAVLink
- SITL container only exposes MAVLink directly

To use Cockpit with SITL, you would need to:
1. Run MAVLink2REST separately
2. Configure it to connect to SITL's TCP port
3. Point Cockpit at MAVLink2REST

This is typically not necessary for development - QGroundControl and Mission Planner are sufficient.

## Next Steps

- [Frames and Models](frames-and-models.md) - Understanding vehicle models
- [Locations and Scenarios](locations-and-scenarios.md) - Setting spawn locations
- [Troubleshooting Guide](troubleshooting-sitl.md) - Common issues and solutions

