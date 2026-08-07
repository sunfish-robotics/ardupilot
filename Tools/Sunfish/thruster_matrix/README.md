# Sunfish Thruster Matrix Tooling

This directory contains Sunfish-specific tooling and configuration files for generating
ArduSub `add_motor_raw_6dof()` mixer rows from measured thruster geometry.

These files are maintained downstream by Sunfish and are not part of upstream ArduPilot.
When rebasing or pulling from ArduPilot main, keep this directory as local project tooling
unless the workflow is intentionally prepared for an upstream contribution.

Run from the repository root:

```sh
Tools/Sunfish/thruster_matrix/thruster_matrix.py --show-scales Tools/Sunfish/thruster_matrix/zoda.json
```

Useful files:

- `zoda.json`: Zoda thruster geometry and orientation source of truth.
- `thruster_matrix.py`: Matrix generator for ArduPilot `add_motor_raw_6dof()` rows.
- `vectored_6dof_bluerov.json`: Reference config for the built-in BlueROV vectored 6DOF frame.
- `simplerov_5.json`: Reference config for the built-in SimpleROV 5 frame.
- `custom_thruster_config_process.html`: Process document for new custom thruster configurations.

Reference:

- [ArduSub frame configurations](https://ardupilot.org/sub/docs/sub-frames.html)
