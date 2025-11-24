# ArduPilot Software-in-the-Loop Dockerfile
# Build with: docker build --platform linux/amd64 --build-arg GIT_COMMIT=$(git rev-parse HEAD) -f sitl.Dockerfile -t ardupilot-sitl:$(git rev-parse HEAD) .
# Uses ardupilot/ardupilot-dev-base which already has all dependencies installed

FROM ardupilot/ardupilot-dev-base:v0.1.3
WORKDIR /ardupilot

ARG GIT_COMMIT=master
ARG VEHICLE_TYPE=ArduSub

# Clone ArduPilot repository using HTTPS with shallow clone to reduce download size
# Using depth 100 to ensure we get the specified commit even if it's not the latest
RUN git clone --depth 100 --recurse-submodules --shallow-submodules https://github.com/sunfish-robotics/ardupilot.git /ardupilot && \
    cd /ardupilot && \
    git checkout ${GIT_COMMIT} && \
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

# Create SITL-specific entrypoint
RUN echo -e '#!/bin/bash\nset -e\ncd /ardupilot\nexec "$@"' > /tmp/sitl_entrypoint.sh && \
    chmod +x /tmp/sitl_entrypoint.sh && \
    mv /tmp/sitl_entrypoint.sh /sitl_entrypoint.sh

# Runtime configuration
ENV BUILDLOGS=/tmp/buildlogs \
    INSTANCE=0 \
    LOCATION=CockburnSound \
    MODEL=ZODA_6DOF \
    SPEEDUP=1 \
    VEHICLE=ArduSub

EXPOSE 5760/tcp
ENTRYPOINT ["/sitl_entrypoint.sh"]
CMD ["/bin/bash", "-c", "Tools/autotest/sim_vehicle.py --vehicle ${VEHICLE} -I${INSTANCE} --custom-location=${LOCATION} -w --frame ${MODEL} --no-rebuild --no-mavproxy --speedup ${SPEEDUP}"]
