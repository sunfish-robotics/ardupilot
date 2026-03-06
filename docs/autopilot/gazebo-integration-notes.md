# Gazebo Integration Notes

High-level overview of integrating ArduPilot SITL with Gazebo for physics-based simulation with sensor plugins.

## Overview

Gazebo provides a physics-based simulation environment that can be integrated with ArduPilot SITL. This enables:
- High-fidelity physics simulation
- Sensor plugins (DVL, pressure sensors, IMU, etc.)
- 3D world modeling with collision detection
- Realistic vehicle dynamics

**Note**: For most Sunfish development tasks, basic SITL (`vectored_6dof`) is sufficient. Use Gazebo when you need sensor simulation or high-fidelity physics.

## Architecture

### Components

1. **ArduPilot SITL**: Runs the autopilot firmware
2. **Gazebo**: Physics simulator with world models
3. **Gazebo Plugins**: Bridge between Gazebo and ArduPilot
4. **ROS Topics** (optional): Communication layer for sensor data

### Communication Flow

```
ArduPilot SITL ←→ Gazebo Plugin ←→ Gazebo World
                      ↕
                  ROS Topics (optional)
                      ↕
                  Sensor Plugins
```

## When to Use Gazebo vs. Basic SITL

### Use Basic SITL (`vectored_6dof`) When:

- ✅ Testing state machines and mission logic
- ✅ Developing Lua scripts
- ✅ Parameter tuning
- ✅ Quick iteration and debugging
- ✅ Validating GCS connectivity

**Advantages**: Faster startup, simpler setup, sufficient for most development

### Use Gazebo When:

- ✅ Testing sensor integration (DVL, pressure, etc.)
- ✅ Validating physics-based behaviors
- ✅ Testing with realistic seafloor models
- ✅ High-fidelity dynamics required
- ✅ Multi-vehicle scenarios

**Disadvantages**: More complex setup, slower startup, requires Gazebo installation

## Gazebo Model Setup

### Model Selection

To use Gazebo with ArduSub, specify a Gazebo model:

```bash
docker run --rm -it -p 5760:5760 \
  -e MODEL=gazebo-bluerov2 \
  ghcr.io/sunfish-robotics/ardupilot/ardupilot-sitl:47333f1da354d963a412b2a9129cca71addece1e
```

**Note**: This requires Gazebo to be running separately. The SITL container alone does not include Gazebo.

### Gazebo World Files

Gazebo uses SDF (Simulation Description Format) files to define:
- World geometry and terrain
- Vehicle models
- Sensor configurations
- Physics parameters (water density, drag coefficients, etc.)

World files are typically `.sdf` or `.world` files.

## Sensor Plugins

### Available Plugins

Gazebo supports various sensor plugins for underwater vehicles:

#### DVL (Doppler Velocity Log)

- **Purpose**: Range and velocity measurements
- **Configuration**: Beam angles, max/min range, number of beams
- **Output**: Range to seafloor, velocity vectors
- **Integration**: Via ROS topics or direct plugin communication

**Key Points**:
- DVL plugins calculate range based on collision detection with world geometry
- Range depends on beam angle and world model (flat surface vs. 3D terrain)
- Can import STL models for realistic seafloor topography

#### Pressure Sensor

- **Purpose**: Depth measurement
- **Configuration**: Sensor offset, calibration
- **Output**: Pressure readings → depth calculations

#### IMU (Inertial Measurement Unit)

- **Purpose**: Orientation and acceleration
- **Configuration**: Noise models, bias, drift
- **Output**: Accelerometer, gyroscope, magnetometer data

### Plugin Configuration

Plugins are configured in SDF files:

```xml
<plugin name="dvl_plugin" filename="libdvl_plugin.so">
  <max_range>100</max_range>
  <min_range>0.1</min_range>
  <beam_count>4</beam_count>
</plugin>
```

Parameters can often be adjusted via XML without recompiling plugins.

## ROS Integration

### Topic-Based Communication

Gazebo plugins typically publish sensor data via ROS topics:

- **IMU data**: `/gazebo/imu/data`
- **DVL data**: `/gazebo/dvl/range` (example)
- **Pressure**: `/gazebo/pressure/data`

ArduPilot can subscribe to these topics (requires ROS integration).

### ROS-Free Operation

Some Gazebo plugins communicate directly with ArduPilot without ROS, using:
- UDP/TCP sockets
- MAVLink messages
- Direct plugin interfaces

## World Modeling

### Flat Surfaces

Simple flat seafloor:
- Constant range readings
- Easy to configure
- Sufficient for basic testing

### 3D Terrain Models

Realistic seafloor:
- Import STL models
- Variable range readings
- More realistic DVL behavior
- Requires terrain data

### STL Model Import

Gazebo can import STL (Stereolithography) models:

```xml
<mesh>
  <uri>model://seafloor.stl</uri>
  <scale>1 1 1</scale>
</mesh>
```

This allows using real-world bathymetry data for simulation.

## Vehicle Dynamics

### Physics Parameters

Gazebo requires physical parameters for realistic simulation:

- **Water density**: Typically 1025 kg/m³ (seawater)
- **Drag coefficients**: Forward, lateral, vertical
- **Center of buoyancy**: Vehicle-specific
- **Center of gravity**: Affects stability
- **Moment of inertia**: Rotational dynamics
- **Thruster models**: Force vs. RPM relationships

### Thruster Simulation

Gazebo can simulate thrusters based on:
- RPM input from autopilot
- Thruster configuration (propeller size, pitch, etc.)
- Force calculations
- Drag effects

**Note**: ArduPilot Gazebo plugins may include built-in thruster models, reducing configuration needed.

## Setup Complexity

### Basic SITL Setup

```bash
# Single command
docker run --rm -it -p 5760:5760 -e MODEL=vectored_6dof <image>
```

**Time**: ~30 seconds to running

### Gazebo Setup

1. Install Gazebo
2. Install ArduPilot Gazebo plugins
3. Configure world files
4. Set up ROS (if using topics)
5. Start Gazebo
6. Start ArduPilot SITL with Gazebo model
7. Connect plugins

**Time**: Hours to days for initial setup

## Fidelity vs. Speed Trade-offs

### Basic SITL

- **Fidelity**: Simplified physics, no sensors
- **Speed**: Fast (real-time or faster with speedup)
- **Use Case**: State machine testing, script development

### Gazebo

- **Fidelity**: High (realistic physics, sensors)
- **Speed**: Slower (may require faster hardware)
- **Use Case**: Sensor testing, physics validation

**Historical Note**: Early simulations prioritized state machine testing over physics accuracy. A simulation might show 100 RPM = 1 m/s while real hardware shows 100 RPM = 3.3 m/s. This is acceptable for behavior testing but insufficient for dynamics validation.

## Recommendations for Sunfish

### Start with Basic SITL

1. Use `vectored_6dof` for initial development
2. Test state machines and mission logic
3. Develop and test Lua scripts
4. Validate GCS workflows

### Consider Gazebo When:

1. You need to test DVL integration
2. Pressure sensor behavior matters
3. Realistic seafloor models are required
4. Physics-based validation is needed

### Migration Path

1. Develop in basic SITL
2. Test in Gazebo for sensor/physics validation
3. Deploy to hardware

## Gazebo Plugin Development

### Creating Custom Plugins

Gazebo plugins are typically written in C++:

1. Implement plugin interface
2. Read configuration from SDF
3. Publish sensor data (ROS topics or direct)
4. Compile as shared library (`.so`)

### Modifying Existing Plugins

Many plugins can be configured via SDF XML:
- Sensor ranges
- Noise models
- Update rates
- Output formats

Check plugin documentation for configurable parameters.

## Environment Variable Interpolation

Gazebo SDF files support environment variable interpolation:

```xml
<plugin>
  <address>${GAZEBO_ADDRESS}</address>
  <port>${GAZEBO_PORT}</port>
</plugin>
```

This allows configuring IP addresses and ports without modifying SDF files.

## Related Documentation

- [Frames and Models](frames-and-models.md) - Understanding `gazebo-bluerov2` model
- [SITL Quickstart](sitl-quickstart-ardusub.md) - Basic SITL setup
- ArduPilot Gazebo Plugin: https://github.com/ArduPilot/ardupilot_gazebo

## Additional Resources

- Gazebo Documentation: http://gazebosim.org/
- ROS Integration: http://wiki.ros.org/
- ArduPilot Gazebo Plugin Repository: Check ArduPilot GitHub organization

