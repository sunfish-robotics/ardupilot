FROM ubuntu:24.04

ARG COMMIT_HASH=master

ENV DEBIAN_FRONTEND=noninteractive

# install git and other dependencies
RUN apt-get update && apt-get install -y git sudo lsb-release tzdata python3 python3-pip && git config --global url."https://github.com/".insteadOf git://github.com/

# Now grab the ArduPilot commit from GitHub and give the default ubuntu user ownership
RUN git init /ardupilot && \
    cd /ardupilot && \
    git remote add origin https://github.com/sunfish-robotics/ardupilot.git && \
    git fetch origin ${COMMIT_HASH} && \
    git checkout --recurse-submodules ${COMMIT_HASH} && \
    chown -R $(id -u ubuntu):$(id -g ubuntu) /ardupilot
WORKDIR /ardupilot

# We can't run the install script as root, so we need to give the default ubuntu user sudo privileges and switch to it
RUN echo "ubuntu ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/ubuntu && chmod 0440 /etc/sudoers.d/ubuntu
USER ubuntu
RUN USER=ubuntu Tools/environment_install/install-prereqs-ubuntu.sh -y

RUN pip3 install empy==3.3.4 pexpect

# Continue build instructions from https://github.com/ArduPilot/ardupilot/blob/master/BUILD.md
RUN ./waf distclean
RUN ./waf configure --board sitl
RUN ./waf sub

# TCP 5760 is what the sim exposes by default
EXPOSE 5760/tcp

# Variables for simulator
ENV INSTANCE=0
# Either a location in Tools/autotest/locations.txt or lat,lon,alt,heading
ENV LOCATION=CockburnSound
ENV MODEL=ZODA_6DOF
ENV SPEEDUP=1
ENV VEHICLE=ArduSub


ENTRYPOINT ["/sitl_entrypoint.sh", "/ardupilot/Tools/autotest/sim_vehicle.py"]

CMD ["--vehicle", "${VEHICLE}", "-I${INSTANCE}", "--custom-location=${LOCATION}", "-w", "--frame", "${MODEL}", "--no-rebuild", "--no-mavproxy", "--speedup", "${SPEEDUP}"]
