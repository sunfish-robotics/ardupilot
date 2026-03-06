# Troubleshooting ArduSub SITL

Common issues and solutions when working with ArduSub Software-in-the-Loop.

## Quick Diagnosis Checklist

When SITL isn't working, check these in order:

1. ✅ Container is running (`docker ps`)
2. ✅ Port 5760 is listening (`netstat -an | grep 5760`)
3. ✅ MODEL environment variable is correct (`vectored_6dof`)
4. ✅ GCS is connecting to correct host/port (`127.0.0.1:5760`)
5. ✅ Container logs show no errors (`docker logs <container_id>`)

## Common Errors and Solutions

### "No Heartbeat Packets Received"

**Symptoms**: Ground control station connects but shows "No heartbeat" error.

**Possible Causes**:

1. **SITL not running**
   - **Check**: `docker ps` shows container
   - **Solution**: Start SITL container

2. **Wrong port**
   - **Check**: GCS connecting to correct port (default: 5760)
   - **Solution**: Verify port mapping: `-p 5760:5760`

3. **Wrong MODEL**
   - **Check**: Container logs show "Vehicle model not found"
   - **Solution**: Use `-e MODEL=vectored_6dof`

4. **Port not listening**
   - **Check**: `netstat -an | grep 5760` or `ss -an | grep 5760`
   - **Solution**: Restart container, check port conflicts

5. **Connection timeout**
   - **Check**: Container logs for errors
   - **Solution**: See container logs section below

**Diagnostic Steps**:

```bash
# 1. Verify container is running
docker ps

# 2. Check if port is listening
netstat -an | grep 5760
# Should show: tcp 0.0.0.0:5760 LISTEN

# 3. Check container logs
docker logs <container_id>

# 4. Test connection
telnet 127.0.0.1 5760
# Should connect (Ctrl+] then quit to exit)
```

### "Vehicle model not found"

**Symptoms**: Container exits immediately or logs show "Vehicle model not found".

**Causes**:

1. **Invalid MODEL value**
   - Wrong spelling: `vectored-6dof` (dash instead of underscore)
   - Wrong case: `VECTORED_6DOF` (should be lowercase)
   - Model doesn't exist

2. **Missing MODEL variable**
   - Environment variable not set

**Solutions**:

```bash
# Correct command
docker run --rm -it -p 5760:5760 \
  -e MODEL=vectored_6dof \
  ghcr.io/sunfish-robotics/ardupilot/ardupilot-sitl:47333f1da354d963a412b2a9129cca71addece1e

# Verify available models
# Check Tools/autotest/pysim/vehicleinfo.py
```

**Common Mistakes**:
- ❌ `MODEL=vectored-6dof` (dash)
- ❌ `MODEL=VECTORED_6DOF` (uppercase)
- ✅ `MODEL=vectored_6dof` (correct)

### Container Exits Immediately

**Symptoms**: Container starts then stops right away.

**Diagnostic Steps**:

```bash
# Check exit code and logs
docker ps -a
docker logs <container_id>
```

**Common Causes**:

1. **Invalid MODEL**: See "Vehicle model not found" above
2. **Missing required files**: Container image corrupted or incomplete
3. **Port conflict**: Port 5760 already in use
4. **Permission issues**: Docker daemon problems

**Solutions**:

1. **Check logs**: `docker logs <container_id>` for specific error
2. **Try different port**: `-p 32768:5760` (map to different host port)
3. **Re-pull image**: `docker pull ghcr.io/sunfish-robotics/ardupilot/ardupilot-sitl:47333f1da354d963a412b2a9129cca71addece1e`
4. **Check Docker**: `docker info` to verify Docker is working

### Port Already in Use

**Symptoms**: `docker run` fails with "port is already allocated" or similar.

**Solutions**:

**Option 1: Use different host port**
```bash
docker run --rm -it -p 32768:5760 \
  -e MODEL=vectored_6dof \
  ghcr.io/sunfish-robotics/ardupilot/ardupilot-sitl:47333f1da354d963a412b2a9129cca71addece1e
```
Then connect GCS to `127.0.0.1:32768`

**Option 2: Find and stop conflicting container**
```bash
# Find what's using port 5760
docker ps | grep 5760
# or
lsof -i :5760

# Stop the conflicting container
docker stop <container_id>
```

**Option 3: Kill process using port**
```bash
# Find process
lsof -i :5760
# or
netstat -tulpn | grep 5760

# Kill process (use PID from above)
kill <PID>
```

### Connection Works But No Telemetry

**Symptoms**: GCS connects but shows no data or zeros.

**Possible Causes**:

1. **SITL still initializing**: Wait a few seconds
2. **EKF issues**: Extended Kalman Filter may be confused
3. **Model limitations**: Some models have limited telemetry

**Solutions**:

1. **Wait**: Give SITL 10-30 seconds to initialize
2. **Check logs**: `docker exec -it <container_id> tail -f /tmp/ardusub.log`
3. **Restart**: Stop and restart container
4. **Check model**: Ensure using `vectored_6dof` (has full telemetry)

### WSL-Specific Issues

#### Serial Ports Not Available

**Symptoms**: Mission Planner on Windows can't see serial ports when Docker runs in WSL.

**Expected Behavior**: Serial ports in WSL are not accessible from Windows applications.

**Solution**: Use TCP connections instead (which work fine):
- Connect to `127.0.0.1:5760` via TCP
- Don't try to use serial ports

#### Port Forwarding Issues

**Symptoms**: Can't connect from Windows to WSL-hosted container.

**Diagnostic**:

```bash
# From WSL, test if port is listening
netstat -an | grep 5760

# From Windows PowerShell, test connection
Test-NetConnection -ComputerName 127.0.0.1 -Port 5760
```

**Solutions**:

1. **Verify port mapping**: Ensure `-p 5760:5760` is correct
2. **Check Windows Firewall**: May block localhost connections
3. **Try from WSL first**: Verify it works within WSL before testing from Windows

#### Network Connectivity

**Symptoms**: Intermittent connections or timeouts.

**Solutions**:

1. **Use WSL2**: WSL2 has better networking than WSL1
2. **Check WSL version**: `wsl --list --verbose`
3. **Restart WSL**: `wsl --shutdown` then restart
4. **Check Docker**: Ensure Docker Desktop WSL integration is enabled

## Container Logs

### Viewing Logs

**Standard output** (when running with `-it`):
```bash
# Logs appear in terminal where container is running
```

**Container logs** (after container exits or in background):
```bash
docker logs <container_id>
docker logs -f <container_id>  # Follow logs
```

**Inside container** (ArduSub-specific log):
```bash
docker exec -it <container_id> /bin/bash
tail -f /tmp/ardusub.log
```

### Log Locations

- **Container stdout**: Standard Docker logs
- **ArduSub log**: `/tmp/ardusub.log` inside container
- **Build logs**: If `BUILD_LOGS` environment variable is set

### What to Look For

**Good startup**:
```
Starting software in the loop Gazebo serial, serial zeros listening on TCP
```

**Errors**:
- `Vehicle model not found` → Check MODEL variable
- `Failed to find location` → Check LOCATION variable
- `Port already in use` → Port conflict
- `Connection refused` → Port not listening

## Location Issues

### "Failed to find location"

**Symptoms**: Container exits with location error.

**Causes**:
- Location name misspelled (case-sensitive)
- Location not in `locations.txt`
- `locations.txt` file missing

**Solutions**:

1. **Check spelling**: Location names are case-sensitive
   ```bash
   # Correct
   -e LOCATION=CockburnSound

   # Wrong
   -e LOCATION=cockburnsound
   -e LOCATION=Cockburn_Sound
   ```

2. **Use direct coordinates**:
   ```bash
   -e LOCATION="-32.265,115.736,0,0"
   ```

3. **Verify location exists**: Check `Tools/autotest/locations.txt`

## Performance Issues

### Slow Simulation

**Symptoms**: SITL runs slowly or lags.

**Solutions**:

1. **Increase SPEEDUP**:
   ```bash
   -e SPEEDUP=10  # Run 10x faster
   ```

2. **Check system resources**: Ensure adequate CPU/RAM
3. **Close other applications**: Free up system resources

### High CPU Usage

**Expected**: SITL can use significant CPU, especially with high SPEEDUP.

**Solutions**:
- Reduce SPEEDUP value
- Close unnecessary applications
- Use more powerful hardware if needed

## GCS Connection Issues

### Mission Planner Won't Connect

**Checklist**:
1. ✅ SITL container running
2. ✅ Port 5760 listening
3. ✅ TCP connection configured correctly (`127.0.0.1:5760`)
4. ✅ No firewall blocking connection
5. ✅ Container logs show no errors

**Test connection**:
```bash
telnet 127.0.0.1 5760
# Should connect (Ctrl+] then quit to exit)
```

### QGroundControl Won't Connect

**Same checklist as Mission Planner**, plus:
- Verify TCP connection settings in QGroundControl
- Check QGroundControl version (older versions may have issues)

## Getting Help

### Information to Collect

When reporting issues, include:

1. **Docker command used** (exact command)
2. **Container logs**: `docker logs <container_id>`
3. **ArduSub log**: `/tmp/ardusub.log` from inside container
4. **System info**: OS, Docker version, WSL version (if applicable)
5. **GCS**: Which GCS and version
6. **Error messages**: Exact error text

### Useful Commands

```bash
# Container status
docker ps -a

# Container logs
docker logs <container_id>

# Port status
netstat -an | grep 5760
# or
ss -an | grep 5760

# Test connection
telnet 127.0.0.1 5760

# Inside container
docker exec -it <container_id> /bin/bash
tail -f /tmp/ardusub.log
```

## Related Documentation

- [SITL Quickstart](sitl-quickstart-ardusub.md) - Basic setup and verification
- [GCS Setup](gcs-setup-qgc-mission-planner.md) - Connection troubleshooting
- [Frames and Models](frames-and-models.md) - Model selection issues
- [Locations and Scenarios](locations-and-scenarios.md) - Location errors

