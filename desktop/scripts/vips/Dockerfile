FROM ubuntu:24.04

RUN set -e && \
apt-get update -y && \
apt-get install -y libvips-tools

ENTRYPOINT ["vips"]
