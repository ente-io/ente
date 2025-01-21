#!/bin/sh

## ImageMagick
#
# We need static builds for Linux and Windows for both x64 and ARM. For this, we
# need a custom workflow because (as of writing):
#
# 1. Upstream doesn't publish ARM64 binaries for Linux
#
# 2. The Windows portable releases are not part of the artifacts attached to the
#    upstream GitHub release.
#
# Our custom workflow is an adaption of the upstream release.yml - its goal is
# to have 4 standalone binaries - Linux x64, Linux ARM, Win x64, Win ARM -
# attached to a GitHub release from which we can pull them when building the
# desktop app.
#
# This is our custom workflow, which runs on a fork of upstream:
# https://github.com/ente-io/ImageMagick/commit/df895cce13d6a3f874a716c05ff2babeb33351b9
# (For reference, we also include a copy of it in this repo - `magick.yml`).
#
# The binaries it creates are available at
# https://github.com/ente-io/ImageMagick/releases/tag/2025-01-21.
#
# This script downloads the relevant binary for the current OS/arch combination
# and places it in the `build` folder. This script runs whenever "yarn install"
# is called as it is set as the "prepare" step in our `package.json`.
#
# On macOS, we don't need ImageMagick since Apple ships `sips`.
