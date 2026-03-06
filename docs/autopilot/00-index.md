# ArduSub SITL Documentation

This documentation set provides practical guidance for Sunfish Robotics engineers working with ArduPilot Software-in-the-Loop (SITL) for underwater autonomous vehicle development and testing.

## Overview

ArduSub SITL allows you to run a simulated ArduPilot autopilot without physical hardware. This is invaluable for:

- **State machine testing**: Verify vehicle behaviors and mission logic before deploying to hardware
- **Lua script development**: Test and debug custom Lua scripts in a controlled environment
- **Parameter tuning**: Experiment with autopilot parameters without risk to physical hardware
- **Mission planning**: Validate mission files and waypoint sequences
- **Integration testing**: Test ground control station (GCS) connectivity and workflows

## Documentation Structure

### Getting Started

- **[SITL Quickstart](sitl-quickstart-ardusub.md)** - Run your first ArduSub SITL instance
  - Docker setup and prerequisites
  - Basic run commands
  - Environment variables
  - Logging and debugging

### Configuration

- **[Frames and Models](frames-and-models.md)** - Understanding vehicle models
  - Why `vectored_6dof` is recommended for Sunfish
  - Available models and their characteristics
  - Model selection guidance

- **[Locations and Scenarios](locations-and-scenarios.md)** - Setting spawn locations
  - Using predefined locations (e.g., Coburn Sound)
  - Custom location specification
  - Location file format

### Ground Control Stations

- **[GCS Setup](gcs-setup-qgc-mission-planner.md)** - Connecting to SITL
  - QGroundControl configuration
  - Mission Planner setup
  - TCP connection details
  - WSL-specific considerations

### Advanced Topics

- **[Gazebo Integration](gazebo-integration-notes.md)** - Physics-based simulation
  - When to use Gazebo vs. basic SITL
  - Plugin architecture overview
  - ROS topic integration
  - Sensor simulation (DVL, pressure, etc.)

- **[MAVLink FTP and Files](mavlink-ftp-and-files.md)** - File transfer operations
  - Uploading Lua scripts
  - Downloading telemetry logs
  - Performance expectations
  - SD card vs. Pi file systems

### Troubleshooting

- **[Troubleshooting Guide](troubleshooting-sitl.md)** - Common issues and solutions
  - "No heartbeat" errors
  - "Vehicle model not found" errors
  - Port mapping issues
  - WSL/Windows-specific problems

## Quick Reference

### Standard Run Command

```bash
docker run --rm -it -p 5760:5760 \
  -e MODEL=vectored_6dof \
  ghcr.io/sunfish-robotics/ardupilot/ardupilot-sitl:47333f1da354d963a412b2a9129cca71addece1e
```

### Common Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `MODEL` | `vectored` | Vehicle model/frame type (use `vectored_6dof` for Sunfish) |
| `LOCATION` | `CockburnSound` | Spawn location name from `locations.txt` |
| `SPEEDUP` | `1` | Simulation speed multiplier |
| `VEHICLE` | `ArduSub` | Vehicle type (typically unchanged) |

### Connection Details

- **Protocol**: MAVLink over TCP
- **Default Port**: `5760`
- **Host**: `127.0.0.1` (localhost)
- **Supported GCS**: QGroundControl, Mission Planner (not Cockpit/BlueOS UI directly)

## Related Resources

- ArduPilot SITL Documentation: https://ardupilot.org/dev/docs/sitl-simulator-software-in the-loop.html
- ArduSub Documentation: https://www.ardusub.com/
- Vehicle Models: `Tools/autotest/pysim/vehicleinfo.py`
- Location Definitions: `Tools/autotest/locations.txt`

