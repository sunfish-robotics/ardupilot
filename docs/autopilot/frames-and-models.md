# Frames and Models

Understanding vehicle models (frames) in ArduSub SITL and selecting the appropriate one for Sunfish Robotics UUV development.

## Overview

ArduSub SITL supports multiple vehicle models, each representing different physical configurations and behaviors. The model you select determines:

- Vehicle dynamics and physics
- Available degrees of freedom (DOF)
- Default parameter sets
- Thruster configurations

## Recommended Model for Sunfish

**Use `vectored_6dof` for Sunfish UUV development.**

This model provides:
- 6 degrees of freedom (surge, sway, heave, roll, pitch, yaw)
- Appropriate for underwater vehicles
- Default parameters tuned for submersible operation
- Compatible with ArduSub's underwater control modes

### Setting the Model

```bash
docker run --rm -it -p 5760:5760 \
  -e MODEL=vectored_6dof \
  ghcr.io/sunfish-robotics/ardupilot/ardupilot-sitl:47333f1da354d963a412b2a9129cca71addece1e
```

## Available ArduSub Models

Model definitions are located in `Tools/autotest/pysim/vehicleinfo.py`. Available models include:

### `vectored`

- **Default frame** for ArduSub
- Basic vectored thruster configuration
- Uses `default_params/sub.parm`
- Suitable for general underwater vehicle testing

### `vectored_6dof` (Recommended)

- **6 degrees of freedom** model
- Uses `default_params/sub-6dof.parm`
- More accurate physics simulation
- Better suited for vehicles requiring full 6DOF control
- **This is the recommended model for Sunfish**

### `gazebo-bluerov2`

- Designed for Gazebo integration
- BlueROV2-specific configuration
- Requires Gazebo to be running
- Uses `default_params/sub.parm`

## Model Selection Guide

### When to Use `vectored_6dof`

- ✅ Testing 6DOF control algorithms
- ✅ Developing missions requiring precise positioning
- ✅ Validating state machine behaviors
- ✅ Sunfish UUV development (recommended)

### When to Use `vectored`

- ✅ Basic functionality testing
- ✅ Simple mission validation
- ✅ Quick parameter checks

### When to Use `gazebo-bluerov2`

- ✅ High-fidelity physics simulation needed
- ✅ Testing sensor integration (DVL, pressure, etc.)
- ✅ Validating Gazebo plugin behavior
- ⚠️ Requires Gazebo setup (more complex)

## Model Definition Location

Vehicle models are defined in:

```
Tools/autotest/pysim/vehicleinfo.py
```

This file contains:
- Model names and aliases
- Default parameter files
- Build targets
- Frame-specific configurations

### Example Model Definition

```python
"ArduSub": {
    "default_frame": "vectored",
    "frames": {
        "vectored": {
            "waf_target": "bin/ardusub",
            "default_params_filename": "default_params/sub.parm",
        },
        "vectored_6dof": {
            "waf_target": "bin/ardusub",
            "default_params_filename": "default_params/sub-6dof.parm",
        },
        "gazebo-bluerov2": {
            "waf_target": "bin/ardusub",
            "default_params_filename": "default_params/sub.parm",
        },
    },
}
```

## Default Parameters

Each model loads a default parameter file:

- **`vectored`**: `default_params/sub.parm`
- **`vectored_6dof`**: `default_params/sub-6dof.parm`
- **`gazebo-bluerov2`**: `default_params/sub.parm`

These parameter files are located in `Tools/autotest/default_params/` and contain vehicle-specific tuning values.

### Viewing Default Parameters

You can inspect default parameters:

```bash
# Inside the SITL container or ArduPilot repo
cat Tools/autotest/default_params/sub-6dof.parm
```

## Gazebo Models vs. SITL Models

### Gazebo Models

Gazebo models (e.g., `gazebo-bluerov2`) require:
- Gazebo simulator running
- SDF (Simulation Description Format) world files
- Gazebo plugins for sensors and physics
- More complex setup

**Gazebo model names** use the format: `gazebo-<model-name>`

### SITL Models

SITL models (e.g., `vectored_6dof`) are:
- Self-contained (no external simulator)
- Simpler to set up
- Faster to start
- Sufficient for most development tasks

**SITL model names** are plain identifiers (e.g., `vectored_6dof`)

## Common Issues

### "Vehicle model not found"

**Cause**: Invalid `MODEL` environment variable value.

**Solution**: Verify the model name matches exactly:
- ✅ `vectored_6dof` (correct)
- ❌ `vectored-6dof` (incorrect - uses dash)
- ❌ `VECTORED_6DOF` (incorrect - case sensitive)

Check available models in `Tools/autotest/pysim/vehicleinfo.py` if unsure.

### Model Doesn't Match Real Vehicle Behavior

**Cause**: SITL models are simplified approximations.

**Solution**:
- For basic testing: Use `vectored_6dof` (good enough for state machine testing)
- For high-fidelity: Consider Gazebo integration (see [Gazebo Integration Notes](gazebo-integration-notes.md))

### Wrong Default Parameters Loaded

**Cause**: Model may be loading unexpected parameter file.

**Solution**: Check which parameter file the model uses in `vehicleinfo.py`, then verify parameters match your needs.

## Custom Models

Creating custom models is possible but requires:
1. Defining the model in `vehicleinfo.py`
2. Creating appropriate default parameter files
3. Implementing model-specific physics (if needed)
4. Rebuilding the SITL container

For most Sunfish development, `vectored_6dof` should be sufficient.

## Related Documentation

- [SITL Quickstart](sitl-quickstart-ardusub.md) - How to run SITL with a specific model
- [Gazebo Integration Notes](gazebo-integration-notes.md) - When to use Gazebo models
- [Troubleshooting Guide](troubleshooting-sitl.md) - Fixing model-related errors

