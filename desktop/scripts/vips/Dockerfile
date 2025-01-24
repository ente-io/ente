FROM ubuntu:24.04

# https://github.com/libvips/libvips/blob/master/.github/workflows/ci.yml
RUN apt-get update -y && apt-get install -y \
    meson pkg-config \
    libarchive-dev libcfitsio-dev libcgif-dev \
    libexif-dev libexpat1-dev libffi-dev \
    libfftw3-dev libheif-dev libheif-plugin-aomenc \
    libheif-plugin-x265 libhwy-dev libimagequant-dev \
    libjpeg-dev libjxl-dev liblcms2-dev \
    libmatio-dev libnifti-dev libopenexr-dev \
    libopenjp2-7-dev libopenslide-dev libpango1.0-dev \
    libpng-dev libpoppler-glib-dev librsvg2-dev \
    libtiff5-dev libwebp-dev

RUN apt-get install -y git && git clone --depth 1 https://github.com/libvips/libvips

WORKDIR /libvips
