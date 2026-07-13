#!/usr/bin/env python3

'''
Calculate ArduPilot 6DOF thruster factors from a JSON geometry file.

AP_FLAKE8_CLEAN
'''

import argparse
import json
import math
import os
import sys


AXES = ("roll", "pitch", "yaw", "throttle", "forward", "lateral")
AXIS_LABELS = {
    "roll": "Roll",
    "pitch": "Pitch",
    "yaw": "Yaw",
    "throttle": "D",
    "forward": "F",
    "lateral": "R",
}
HANDEDNESS = {
    "cw": -1.0,
    "ccw": 1.0,
}
EXAMPLE_CONFIG_FILE = "vectored_6dof_bluerov.json"


def fail(message):
    print("thruster_matrix.py: %s" % message, file=sys.stderr)
    sys.exit(1)


def get_number(mapping, name, context):
    value = mapping.get(name)
    if not isinstance(value, (int, float)):
        fail("%s.%s must be a number" % (context, name))
    return float(value)


def get_vector(mapping, name, context):
    value = mapping.get(name)
    if not isinstance(value, dict):
        fail("%s.%s must be an object" % (context, name))
    return (
        get_number(value, "x", "%s.%s" % (context, name)),
        get_number(value, "y", "%s.%s" % (context, name)),
        get_number(value, "z", "%s.%s" % (context, name)),
    )


def get_orientation(thruster, context):
    orientation = thruster.get("orientation")
    if not isinstance(orientation, dict):
        fail("%s.orientation must be an object" % context)
    if all(axis in orientation for axis in ("x", "y", "z")):
        return normalised(get_vector(thruster, "orientation", context), context)

    # Config yaw and pitch are degrees. Yaw is measured in the body X/Y plane,
    # and pitch tilts positive toward body Z.
    yaw = math.radians(get_number(orientation, "yaw", "%s.orientation" % context))
    pitch = math.radians(get_number(orientation, "pitch", "%s.orientation" % context))
    return (
        math.cos(pitch) * math.cos(yaw),
        math.cos(pitch) * math.sin(yaw),
        math.sin(pitch),
    )


def vector_length(vector):
    return math.sqrt(sum(value * value for value in vector))


def normalised(vector, context):
    length = vector_length(vector)
    if length <= 0.0:
        fail("%s orientation vector must not be zero length" % context)
    return tuple(value / length for value in vector)


def cross(left, right):
    return (
        left[1] * right[2] - left[2] * right[1],
        left[2] * right[0] - left[0] * right[2],
        left[0] * right[1] - left[1] * right[0],
    )


def add(left, right):
    return tuple(left[i] + right[i] for i in range(3))


def scale(vector, factor):
    return tuple(value * factor for value in vector)


def parse_handedness(thruster, context):
    handedness = thruster.get("handedness", thruster.get("spin"))
    if handedness is None:
        fail("%s.handedness is required" % context)
    handedness = str(handedness).lower()
    if handedness not in HANDEDNESS:
        fail("%s.handedness must be one of: %s" % (context, ", ".join(sorted(HANDEDNESS))))
    return HANDEDNESS[handedness]


def parse_thruster(thruster, index):
    context = "thrusters[%u]" % index
    if not isinstance(thruster, dict):
        fail("%s must be an object" % context)
    motor = thruster.get("motor", index + 1)
    if not isinstance(motor, int):
        fail("%s.motor must be an integer" % context)
    if motor < 1:
        fail("%s.motor must be at least 1" % context)
    position = get_vector(thruster, "position", context)
    orientation = get_orientation(thruster, context)
    handedness = parse_handedness(thruster, context)
    description = str(thruster.get("description", ""))
    return {
        "motor": motor,
        "description": description,
        "position": position,
        "orientation": orientation,
        "handedness": handedness,
    }


def load_config(filename):
    try:
        with open(filename, encoding="utf-8") as config_file:
            config = json.load(config_file)
    except OSError as error:
        fail("failed to read %s: %s" % (filename, error))
    except json.JSONDecodeError as error:
        fail("failed to parse %s: %s" % (filename, error))

    thrusters = config.get("thrusters")
    if not isinstance(thrusters, list):
        fail("config must contain a thrusters array")
    motor_count = config.get("motor_count", 8)
    if not isinstance(motor_count, int) or motor_count < 1:
        fail("motor_count must be a positive integer")
    if len(thrusters) != motor_count:
        fail("expected %u thrusters, got %u" % (motor_count, len(thrusters)))

    parsed = [parse_thruster(thruster, i) for i, thruster in enumerate(thrusters)]
    motors = [thruster["motor"] for thruster in parsed]
    if len(set(motors)) != len(motors):
        fail("motor numbers must be unique")
    return config, parsed


def get_handedness_torque_factor(config, override):
    if override is not None:
        return override
    value = config.get("handedness_torque_factor", config.get("spin_torque_factor", 0.0))
    if not isinstance(value, (int, float)):
        fail("handedness_torque_factor must be a number")
    return float(value)


def calculate_factors(thrusters, handedness_torque_factor):
    factors = []
    for thruster in thrusters:
        force = thruster["orientation"]
        moment = cross(thruster["position"], force)
        handedness_moment = scale(force, thruster["handedness"] * handedness_torque_factor)
        moment = add(moment, handedness_moment)
        factors.append({
            "motor": thruster["motor"],
            "description": thruster["description"],
            "roll": -moment[0],
            "pitch": -moment[1],
            "yaw": moment[2],
            "throttle": force[2],
            "forward": force[0],
            "lateral": force[1],
        })
    return factors


def normalise_factors(factors, axes):
    scale_factors = {}
    for axis in axes:
        axis_max = max(abs(factor[axis]) for factor in factors)
        scale_factors[axis] = axis_max
        if axis_max > 0.0:
            for factor in factors:
                factor[axis] /= axis_max
    return scale_factors


def format_float(value):
    if abs(value) < 0.0005:
        value = 0.0
    return "%.3f" % value


def format_float_cpp(value):
    if abs(value) < 0.0005:
        return "0"
    return "%sf" % format_float(value)


def print_table(factors):
    header = ("Motor", "Description") + tuple(AXIS_LABELS[axis] for axis in AXES)
    widths = [len(name) for name in header]
    rows = []
    for factor in sorted(factors, key=lambda item: item["motor"]):
        row = [str(factor["motor"]), factor["description"]] + [format_float(factor[axis]) for axis in AXES]
        widths = [max(widths[i], len(row[i])) for i in range(len(row))]
        rows.append(row)

    print(" ".join(header[i].rjust(widths[i]) for i in range(len(header))))
    print(" ".join("-" * width for width in widths))
    for row in rows:
        print(" ".join(row[i].rjust(widths[i]) for i in range(len(row))))


def print_ardupilot_lines(factors):
    print()
    print("ArduPilot AP_Motors6DOF lines:")
    print("// add_motor_raw_6dof order: Motor, Roll, Pitch, Yaw, D, F, R, Test order")
    print("//                 Motor #          Roll    Pitch      Yaw       D       F       R  Test")
    for factor in sorted(factors, key=lambda item: item["motor"]):
        comment = ""
        if factor["description"]:
            comment = " // %s" % factor["description"]
        print(
            "add_motor_raw_6dof(%-15s %8s, %8s, %8s, %8s, %8s, %8s, %u);%s"
            % (
                "AP_MOTORS_MOT_%u," % factor["motor"],
                format_float_cpp(factor["roll"]),
                format_float_cpp(factor["pitch"]),
                format_float_cpp(factor["yaw"]),
                format_float_cpp(factor["throttle"]),
                format_float_cpp(factor["forward"]),
                format_float_cpp(factor["lateral"]),
                factor["motor"],
                comment,
            )
        )


def print_scale_factors(scale_factors):
    print()
    print("Normalisation scale factors:")
    for axis in AXES:
        print("  %s: %s" % (axis, format_float(scale_factors[axis])))


def write_example_config(filename):
    example_filename = os.path.join(os.path.dirname(__file__), EXAMPLE_CONFIG_FILE)
    try:
        with open(example_filename, encoding="utf-8") as example:
            config = json.load(example)
        with open(filename, "w", encoding="utf-8") as output:
            json.dump(config, output, indent=4)
            output.write("\n")
    except OSError as error:
        fail("failed to write %s: %s" % (filename, error))
    except json.JSONDecodeError as error:
        fail("failed to parse %s: %s" % (example_filename, error))


def parse_arguments():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("config", nargs="?", help="JSON thruster geometry file")
    parser.add_argument("--handedness-torque-factor", type=float,
                        help="optional prop handedness torque per unit thrust; use 0 if actual spin direction is unknown")
    parser.add_argument("--no-normalize", action="store_true",
                        help="print raw geometry factors instead of normalising each axis")
    parser.add_argument("--show-scales", action="store_true",
                        help="show the per-axis normalisation factors")
    parser.add_argument("--write-example", metavar="FILE",
                        help="write an example 8-thruster JSON configuration using yaw/pitch degrees and exit")
    return parser.parse_args()


def main():
    args = parse_arguments()
    if args.write_example is not None:
        write_example_config(args.write_example)
        return
    if args.config is None:
        fail("config is required unless --write-example is used")

    config, thrusters = load_config(args.config)
    handedness_torque_factor = get_handedness_torque_factor(config, args.handedness_torque_factor)
    factors = calculate_factors(thrusters, handedness_torque_factor)

    should_normalise = config.get("normalize", True) and not args.no_normalize
    scale_factors = None
    if should_normalise:
        scale_factors = normalise_factors(factors, AXES)

    print_table(factors)
    print_ardupilot_lines(factors)
    if args.show_scales and scale_factors is not None:
        print_scale_factors(scale_factors)


if __name__ == "__main__":
    main()
