#!/bin/sh

# This script is run by the Cloudflare Pages integration when deploying the apps
# in this repository. The app to build and the environment variables to use is
# decided based on the the value of the CF_PAGES_BRANCH environment variable.
#
# Ref: https://developers.cloudflare.com/pages/how-to/build-commands-branches/

set -o errexit
set -o xtrace

# The Cloudflare Pages build configuration is set to use `out/` as the build
# output directory, so once we're done building we copy the app specific output
# to `out/` (symlinking didn't work).

rm -rf out

# Cloudflare Pages has two separate environments - Production and Preview.
#
# Each of these have their separate environment variables. However, we need to
# deploy multiple production apps - so while for the "photos-release" branch
# (which corresponds to Cloudflare's "Production" environment) can have separate
# environment variables, the rest of the production deployments share the same
# environment variables (those that are set for the Preview environment in CF).
#
# So we instead tune environment variables for specific deployments here.

if test "$CF_PAGES_BRANCH" = "photos-release"; then
    yarn export:photos
    cp -R apps/photos/out .
elif test "$CF_PAGES_BRANCH" = "auth-release"; then
    yarn export:auth
    cp -R apps/auth/out .
else
    # Apart from the named branches, everything else gets treated as a
    # development deployment.
    export NODE_ENV=development
    # Also, we connect all of them to the dev APIs.
    export NEXT_PUBLIC_ENTE_ENDPOINT=https://dev-api.ente.io
    export NEXT_PUBLIC_ENTE_ALBUM_ENDPOINT=https://dev-albums.ente.io

    yarn export:photos
    cp -R apps/photos/out .
fi
