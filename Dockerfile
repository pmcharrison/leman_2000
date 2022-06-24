FROM ubuntu:20.04
LABEL org.opencontainers.image.source https://github.com/pmcharrison/leman_2000

# Install the MCR dependencies and some things we'll need and download the MCR
# from Mathworks -silently install it
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get -qq update && apt-get -qq install -y \
    unzip \
    xorg \
    wget \
    curl && \
    mkdir /mcr-install && \
    mkdir /opt/mcr && \
    cd /mcr-install && \
    wget http://www.mathworks.com/supportfiles/downloads/R2014b/deployment_files/R2014b/installers/glnxa64/MCR_R2014b_glnxa64_installer.zip && \
    cd /mcr-install && \
    unzip -q MCR_R2014b_glnxa64_installer.zip && \
    ./install -destinationFolder /opt/mcr -agreeToLicense yes -mode silent && \
    cd / && \
    rm -rf mcr-install
    
RUN apt-get update && apt-get install -y \
  build-essential \
  libncurses5 \
  libxext-dev \
  libxtst6 \
  libxt6 \
  libglu1

# Configure environment variables for MCR
ENV LD_LIBRARY_PATH /opt/mcr/v84/runtime/glnxa64:/opt/mcr/v84/bin/glnxa64:/opt/mcr/v84/sys/os/glnxa64
ENV XAPPLRESDIR /opt/mcr/v84/X11/app-defaults

#
COPY leman_2000/for_redistribution_files_only leman_2000/for_redistribution_files_only
COPY leman_2000_docker.sh leman_2000_docker.sh

ENTRYPOINT ["/leman_2000_docker.sh"]

