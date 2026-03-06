# Locations and Scenarios

Configuring spawn locations for ArduSub SITL to test missions and behaviors at specific geographic locations.

## Overview

ArduSub SITL can spawn at predefined locations or custom coordinates. This is useful for:
- Testing missions at known locations (e.g., Coburn Sound)
- Validating GPS-dependent behaviors
- Testing at specific altitudes/depths
- Reproducing scenarios at real-world sites

## Using Predefined Locations

ArduPilot includes a `locations.txt` file with many predefined locations. To use one:

```bash
docker run --rm -it -p 5760:5760 \
  -e MODEL=vectored_6dof \
  -e LOCATION=CockburnSound \
  ghcr.io/sunfish-robotics/ardupilot/ardupilot-sitl:47333f1da354d963a412b2a9129cca71addece1e
```

### Available Locations

The `locations.txt` file is located at `Tools/autotest/locations.txt` and contains entries in the format:

```
NAME=latitude,longitude,absolute-altitude,heading
```

#### Common Locations for Underwater Testing

| Location Name | Coordinates | Altitude | Notes |
|---------------|--------------|----------|-------|
| `CockburnSound` | -32.265419884714895, 115.73602611372627 | 0m | Western Australia (default) |
| `CMAC` | -35.363261, 149.165230 | 584m | Canberra, Australia |
| `OSRF0` | 37.4003371, -122.0800351 | 0m | Open Source Robotics Foundation |
| `RATBeach` | 33.810313, -118.393867 | 0m | California, USA (coastal) |

#### Full Location List

See `Tools/autotest/locations.txt` for the complete list of available locations. The file includes locations worldwide for various testing scenarios.

### Location File Format

Each line in `locations.txt` follows this format:

```
NAME=latitude,longitude,absolute-altitude,heading
```

Where:
- **NAME**: Location identifier (case-sensitive)
- **latitude**: Decimal degrees (negative = South)
- **longitude**: Decimal degrees (negative = West)
- **absolute-altitude**: Meters above sea level (for underwater: use 0 or negative)
- **heading**: Initial vehicle heading in degrees (0-360, 0 = North)

### Example Entry

```
CockburnSound=-32.265419884714895,115.73602611372627,0,0
```

This spawns the vehicle at:
- **Latitude**: -32.265° (32.265° South)
- **Longitude**: 115.736° (115.736° East)
- **Altitude**: 0m (sea level)
- **Heading**: 0° (facing North)

## Custom Locations

You can specify custom coordinates directly without using `locations.txt`:

```bash
docker run --rm -it -p 5760:5760 \
  -e MODEL=vectored_6dof \
  -e LOCATION="-32.265419884714895,115.73602611372627,0,0" \
  ghcr.io/sunfish-robotics/ardupilot/ardupilot-sitl:47333f1da354d963a412b2a9129cca71addece1e
```

**Format**: `latitude,longitude,altitude,heading`

### Custom Location Examples

**Spawn at specific coordinates with custom heading**:
```bash
-e LOCATION="-27.274439,151.290064,0,90"
```
Spawns at Dalby, Queensland, facing East (90°).

**Spawn underwater**:
```bash
-e LOCATION="-32.265,115.736,-10,0"
```
Spawns 10 meters below sea level (negative altitude).

## Adding New Locations

To add a new location to `locations.txt`:

1. **Edit the file** (in the ArduPilot repository):
   ```
   Tools/autotest/locations.txt
   ```

2. **Add a new line**:
   ```
   YourLocationName=latitude,longitude,altitude,heading
   ```

3. **Rebuild the SITL container** (if using a custom build) or the location will be available if the file is included in the container image.

### Example: Adding Coburn Sound

If Coburn Sound wasn't already in the file, you would add:

```
CoburnSound=-32.265419884714895,115.73602611372627,0,0
```

**Note**: The container includes the locations.txt file from the ArduPilot repository. To use custom locations without modifying the container, use the direct coordinate format instead.

## Location Selection Behavior

### Default Location

If `LOCATION` is not specified, SITL uses a default location (typically `CockburnSound` or the first valid location in `locations.txt`).

### Location Lookup Process

1. SITL checks if `LOCATION` contains a comma (indicating direct coordinates)
2. If no comma, SITL looks up the name in `locations.txt`
3. If found, uses coordinates from the file
4. If not found, reports an error: `Failed to find location`

### Error Handling

**"Failed to find location"**:
- Location name not in `locations.txt`
- Location name misspelled (case-sensitive)
- `locations.txt` file missing or corrupted

**Solution**:
- Verify location name spelling
- Check `Tools/autotest/locations.txt` for available names
- Use direct coordinate format instead

## Altitude Considerations

### Sea Level Reference

- **0m**: Sea level (surface)
- **Negative values**: Below sea level (underwater)
- **Positive values**: Above sea level (land/air)

### Underwater Spawning

For underwater vehicles, you typically want to spawn at or below sea level:

```bash
# Spawn 5 meters underwater
-e LOCATION="-32.265,115.736,-5,0"
```

**Note**: SITL's physics simulation may handle negative altitudes differently than real GPS systems. Test behavior to ensure it matches expectations.

## Heading (Initial Orientation)

The heading parameter sets the initial vehicle orientation:

- **0°**: North
- **90°**: East
- **180°**: South
- **270°**: West

This affects:
- Initial compass reading
- Vehicle orientation in GCS displays
- Mission waypoint calculations (relative to initial heading)

## Use Cases

### Testing at Known Sites

Spawn at real-world test locations to validate mission planning:

```bash
-e LOCATION=CockburnSound
```

### Reproducing Scenarios

Use consistent locations for reproducible testing:

```bash
# Always spawn at the same location for consistent testing
-e LOCATION=CMAC
```

### Custom Mission Testing

Spawn at custom coordinates matching your mission waypoints:

```bash
-e LOCATION="-32.265,115.736,0,0"
```

## Integration with Mission Planning

When planning missions in your GCS:

1. **Set spawn location** to match your mission area
2. **Plan waypoints** relative to spawn location
3. **Test mission** in SITL before deploying to hardware

This ensures missions work correctly at the intended location.

## Related Documentation

- [SITL Quickstart](sitl-quickstart-ardusub.md) - Basic SITL setup
- [Troubleshooting Guide](troubleshooting-sitl.md) - Fixing location-related errors
- [GCS Setup](gcs-setup-qgc-mission-planner.md) - Viewing location in ground control stations

