# MAVLink FTP and Files

Using MAVLink FTP to transfer files to and from ArduSub SITL, including Lua scripts and telemetry logs.

## Overview

MAVLink FTP is a file transfer protocol that allows ground control stations to access the autopilot's file system over MAVLink. This is useful for:
- Uploading Lua scripts
- Downloading telemetry logs
- Managing files on the autopilot SD card
- Transferring configuration files

**Important**: MAVLink FTP is very slow (~32 kbps even on localhost). Use it for small files and scripts, not large data transfers.

## Supported Ground Control Stations

### Mission Planner

✅ **Full Support** - Includes MAVLink FTP client

Mission Planner is the recommended tool for file transfers due to its built-in MAVLink FTP support.

### QGroundControl

❌ **No Support** - Does not include MAVLink FTP client

QGroundControl cannot transfer files via MAVLink FTP. Use Mission Planner for file operations.

## Accessing MAVLink FTP in Mission Planner

### Prerequisites

1. Mission Planner installed and running
2. Connected to ArduSub SITL (see [GCS Setup Guide](gcs-setup-qgc-mission-planner.md))
3. SITL container running and responsive

### Opening MAVLink FTP

1. **Connect to SITL** (if not already connected)
2. **Navigate to**: Config/Tuning → **MAVLink FTP**
3. **File browser** will display the autopilot's file system

### File System Structure

The SITL container's file system structure:

```
/
├── ... (ArduPilot repository files)
└── [SD card mount point, if configured]
```

**Note**: The container runs from the ArduPilot repository root. Files uploaded may be placed in various locations depending on configuration.

## Uploading Files

### Uploading Lua Scripts

Lua scripts are commonly uploaded for custom behaviors:

1. **Open MAVLink FTP** in Mission Planner
2. **Navigate** to the scripts directory (typically `/scripts` or similar)
3. **Right-click** → **Upload File**
4. **Select** your `.lua` file
5. **Wait** for transfer to complete (may take a while due to slow transfer speed)

### Upload Process

- **Transfer size**: Maximum 242 bytes per packet
- **Acknowledgment**: Each packet waits for ACK before sending next
- **Speed**: ~32 kbps under ideal conditions (localhost)
- **Time estimate**: ~1 minute per 20KB file on localhost

**Note**: Transfer speed degrades significantly over network connections (4G, VPN, etc.).

## Downloading Files

### Downloading Telemetry Logs

Telemetry logs can be saved to the SD card and retrieved:

1. **Configure logging** in ArduPilot parameters (if needed)
2. **Run mission** or flight to generate logs
3. **Open MAVLink FTP** in Mission Planner
4. **Navigate** to log directory (typically `/logs` or SD card root)
5. **Right-click** on log file → **Download**
6. **Save** to local computer

### Log File Locations

Logs are typically stored in:
- SD card root directory
- `/logs` subdirectory
- Container-specific paths (check SITL configuration)

## File Operations

### Supported Operations

- ✅ **Upload**: Transfer files from computer to autopilot
- ✅ **Download**: Transfer files from autopilot to computer
- ✅ **Delete**: Remove files from autopilot
- ❌ **Delete Folders**: Not supported (can only delete individual files)

### Limitations

- **No folder deletion**: Cannot delete directories via MAVLink FTP
- **Slow transfers**: Very slow even on localhost
- **Small packet size**: 242 bytes per packet maximum
- **Sequential transfers**: One file at a time

## Performance Characteristics

### Transfer Speed

| Connection Type | Approximate Speed | Notes |
|----------------|-------------------|-------|
| Localhost (SITL) | ~32 kbps | Best case scenario |
| 4G Network | ~5-10 kbps | Degrades with latency |
| VPN + 4G | ~2-5 kbps | Multiple hops increase latency |

### Real-World Example

Transferring a 20KB Lua script:
- **Localhost**: ~1 minute
- **4G direct**: ~3-5 minutes
- **VPN + 4G**: ~8-15 minutes

**Recommendation**: Develop and test scripts locally before uploading over network connections.

## Use Cases

### Lua Script Development

1. **Develop script** locally
2. **Test syntax** (if possible) before upload
3. **Upload via MAVLink FTP** to SITL
4. **Test script** in SITL
5. **Iterate** as needed

**Tip**: Keep scripts small to minimize upload time. Break large scripts into modules if possible.

### Telemetry Log Retrieval

1. **Configure logging** parameters
2. **Run mission** in SITL
3. **Download logs** via MAVLink FTP
4. **Analyze logs** using Mission Planner or other tools

### Configuration File Management

1. **Export parameters** from Mission Planner
2. **Modify** parameter file if needed
3. **Upload** modified parameters (if supported)
4. **Load parameters** on autopilot

## SD Card vs. Raspberry Pi File Systems

### ArduPilot SD Card

- **Location**: Physical SD card in autopilot hardware
- **Access**: Via MAVLink FTP
- **Purpose**: Logs, scripts, parameter backups
- **SITL**: Simulated SD card (container file system)

### Raspberry Pi File System

- **Location**: Raspberry Pi storage (SSD, SD card, etc.)
- **Access**: SSH, SCP, or BlueOS file browser
- **Purpose**: Videos, large logs, application data
- **Not accessible**: Via MAVLink FTP (different system)

**Important**: MAVLink FTP only accesses the autopilot's file system, not the Raspberry Pi's file system.

## File System in SITL Container

### Container Structure

The SITL container includes:
- Full ArduPilot repository (for build requirements)
- Git history (required by build scripts)
- Default parameter files
- Script directories

### File Persistence

**Important**: Files uploaded to the container are **ephemeral**:
- ✅ Available while container is running
- ❌ Lost when container stops (unless using volumes)
- ❌ Not persisted between container runs

### Persisting Files

To persist files across container restarts:

1. **Use Docker volumes** to mount host directories
2. **Copy files** from container before stopping
3. **Rebuild container** with files included (advanced)

## Troubleshooting

### "Transfer Failed" or Timeout

**Causes**:
- Network connectivity issues
- Container stopped or unresponsive
- File too large
- MAVLink connection lost

**Solutions**:
- Verify SITL is running and connected
- Check MAVLink connection status
- Try smaller files first
- Retry transfer

### Very Slow Transfers

**Expected**: MAVLink FTP is inherently slow due to protocol limitations.

**Optimization**:
- Use localhost connections when possible
- Minimize file sizes
- Avoid transferring during active missions
- Consider alternative transfer methods for large files

### File Not Found After Upload

**Causes**:
- Uploaded to wrong directory
- Container restarted (files lost)
- File system permissions

**Solutions**:
- Check upload destination in Mission Planner
- Verify container hasn't restarted
- Check file system permissions (if accessible)

### Cannot Delete Folders

**Expected Behavior**: MAVLink FTP does not support folder deletion.

**Workaround**: Delete individual files within folders, or use other access methods if available.

## Best Practices

### For Lua Scripts

1. **Develop locally** with syntax checking
2. **Test in SITL** before deploying to hardware
3. **Keep scripts modular** (smaller files = faster uploads)
4. **Version control** scripts in git
5. **Document** script purpose and usage

### For Log Files

1. **Configure logging** appropriately (avoid excessive logging)
2. **Download logs** regularly (don't let them accumulate)
3. **Archive logs** locally after download
4. **Clear old logs** from autopilot to save space

### For Development Workflow

1. **Use SITL** for initial script development
2. **Test thoroughly** before uploading to hardware
3. **Upload over network** only when necessary
4. **Keep backups** of all uploaded files

## Related Documentation

- [GCS Setup Guide](gcs-setup-qgc-mission-planner.md) - Connecting Mission Planner to SITL
- [SITL Quickstart](sitl-quickstart-ardusub.md) - Basic SITL setup
- ArduPilot Lua Scripting: https://ardupilot.org/dev/docs/lua-scripts.html

## Additional Notes

- MAVLink FTP is the **only way** to access the autopilot SD card without physically removing it
- Transfer speed is limited by protocol design, not network bandwidth
- Consider file size and transfer time when planning workflows
- For large files or frequent transfers, consider alternative methods (if available)

