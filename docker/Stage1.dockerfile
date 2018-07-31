# Part 1 of building toolchain image, install required development tools
FROM ubuntu:18.04

LABEL maintainer simon.cook@embecosm.com

# Enable source repositories for updated Ubuntu packages
RUN sed -i -e 's/^# deb-src/deb-src/' /etc/apt/sources.list

# Install required packages
RUN apt-get -y update && \
  DEBIAN_FRONTEND=noninteractive \
  apt-get install -y build-essential git gawk wget libmpc-dev python pkg-config && \
  DEBIAN_FRONTEND=noninteractive \
  apt-get build-dep -y gcc gdb binutils qemu
