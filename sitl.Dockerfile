# ArduPilot Software-in-the-Loop Dockerfile
#
# You can use the following command to build the image:
#   docker build --build-arg GIT_COMMIT=$(git rev-parse HEAD) \
#     --build-arg BASE_IMAGE=ardupilot/ardupilot-dev-base \
#     -f sitl.Dockerfile \
#     -t ardupilot-sitl:$(git rev-parse HEAD) .
#
# There are a couple of useful extension points in the Dockerfile:
# - The default working dir is `/sitl/workdir`, so you can mount your Lua scripts
#   to `/sitl/workdir/APM/scripts` and they'll be loaded automatically.
# - You can override the autopilot parameters by mounting a file to `/sitl/init.params`


# Note:
ARG BASE_IMAGE=ardupilot/ardupilot-dev-base
ARG IMAGE_VERSION=v0.1.5

FROM ${BASE_IMAGE}:${IMAGE_VERSION}
WORKDIR /ardupilot

ARG GIT_COMMIT=master
ARG VEHICLE_TYPE=ArduSub

# Clone ArduPilot repository using HTTPS with shallow clone to reduce download size
# Using depth 100 to ensure we get the specified commit even if it's not the latest
RUN git clone --depth 100 --recurse-submodules --shallow-submodules https://github.com/sunfish-robotics/ardupilot.git /ardupilot && \
    cd /ardupilot && \
    (git checkout ${GIT_COMMIT} 2>/dev/null || (git fetch origin ${GIT_COMMIT} && git checkout ${GIT_COMMIT})) && \
    git submodule update --init --recursive --depth 1

# Build ArduPilot SITL
RUN BUILD_TARGET=$(case "${VEHICLE_TYPE}" in \
        ArduSub|Sub) echo "bin/ardusub" ;; \
        ArduCopter|Copter) echo "bin/arducopter" ;; \
        ArduPlane|Plane) echo "bin/arduplane" ;; \
        ArduRover|Rover) echo "bin/ardurover" ;; \
        Blimp) echo "bin/blimp" ;; \
        AntennaTracker|Tracker) echo "bin/antennatracker" ;; \
        *) echo "bin/ardusub" ;; \
    esac) && \
    cd /ardupilot && \
    ./waf configure --board sitl && \
    ./waf build --target ${BUILD_TARGET}

# Create SITL-specific entrypoint that sources the environment
RUN export SITL_ENTRYPOINT="/tmp/sitl_entrypoint.sh" && \
    echo "#!/bin/bash" > $SITL_ENTRYPOINT && \
    echo "set -e" >> $SITL_ENTRYPOINT && \
    echo "if [ -f /home/ardupilot/.ardupilot_env ]; then" >> $SITL_ENTRYPOINT && \
    echo "  source /home/ardupilot/.ardupilot_env" >> $SITL_ENTRYPOINT && \
    echo "fi" >> $SITL_ENTRYPOINT && \
    echo "cd /ardupilot" >> $SITL_ENTRYPOINT && \
    echo 'exec "$@"' >> $SITL_ENTRYPOINT && \
    chmod +x $SITL_ENTRYPOINT && \
    sudo mv $SITL_ENTRYPOINT /sitl_entrypoint.sh

RUN mkdir -p /sitl/workdir && touch /sitl/init.params

# Healthy when we are waiting for a connection and there were no segmentation faults
HEALTHCHECK --interval=10s --timeout=5s --start-period=5s --retries=3 \
    CMD test -r /tmp/ArduSub.log && grep -Fq "Waiting for connection ...." /tmp/ArduSub.log && ! grep -Fq "ERROR: segmentation fault - aborting" /tmp/ArduSub.log

# Runtime configuration
ENV INSTANCE=0 \
    LOCATION=CockburnSound \
    MODEL=vectored_6dof \
    SPEEDUP=1 \
    VEHICLE=ArduSub

RUN mkdir -p /sitl/workdir && touch /sitl/sitl.params

EXPOSE 5760/tcp
ENTRYPOINT ["/sitl_entrypoint.sh"]
CMD ["/bin/bash", "-c", "Tools/autotest/sim_vehicle.py --vehicle=${VEHICLE} --instance=${INSTANCE} --location=${LOCATION} -w --frame=${MODEL} --no-rebuild --no-mavproxy --speedup=${SPEEDUP} --sim-address=0.0.0.0 --use-dir=/sitl/workdir --add-param-file=/sitl/init.params"]
