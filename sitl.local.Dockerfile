# ArduPilot SITL image built from local repo (for FDM/simulator development).
# Build from ardupilot repo root: docker build -f sitl.local.Dockerfile -t ardupilot-sitl:local .

ARG BASE_IMAGE=ardupilot/ardupilot-dev-base
ARG IMAGE_VERSION=v0.1.5

FROM ${BASE_IMAGE}:${IMAGE_VERSION}
WORKDIR /ardupilot

ARG VEHICLE_TYPE=ArduSub

# Use local tree from build context (no clone)
COPY . .

# Ensure submodules are present (e.g. for waf)
RUN if [ -f .gitmodules ] && [ -s .gitmodules ]; then \
      git submodule update --init --recursive; \
    fi

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
    ./waf configure --board sitl && \
    ./waf build --target ${BUILD_TARGET}

# Create SITL-specific entrypoint
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

ENV INSTANCE=0 \
    LOCATION=CockburnSound \
    MODEL=vectored_6dof \
    SPEEDUP=1 \
    VEHICLE=ArduSub

RUN mkdir -p /sitl/workdir && touch /sitl/sitl.params

EXPOSE 5760/tcp
ENTRYPOINT ["/sitl_entrypoint.sh"]
CMD ["/bin/bash", "-c", "Tools/autotest/sim_vehicle.py --vehicle=${VEHICLE} --instance=${INSTANCE} --location=${LOCATION} -w --frame=${MODEL} --no-rebuild --no-mavproxy --speedup=${SPEEDUP} --sim-address=0.0.0.0 --use-dir=/sitl/workdir/"]
