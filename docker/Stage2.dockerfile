# Part 2 of building toolchain image - install built toolchain
FROM ubuntu:18.04

LABEL maintainer simon.cook@embecosm.com

# Install useful packages
RUN apt-get -y update && \
  DEBIAN_FRONTEND=noninteractive \
  apt-get install -y build-essential \
  libglib2.0 libaio1 libiscsi7 libcurl3-gnutls librbd1 libbabeltrace1

COPY --chown=0:0 install/ /usr/local/
