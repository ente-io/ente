#!/bin/sh

# This script is run by the Cloudflare Pages integration when deploying the apps
# in this repository. The app to build is decided based on the the value of the
# CF_PAGES_BRANCH environment variable.
#
# Ref: https://developers.cloudflare.com/pages/how-to/build-commands-branches/
#
# The CF Pages configuration is set to use `out/` as the build output directory,
# so once we're done building we copy the app specific output to `out/`.

set -o errexit
set -o xtrace

rm -rf out

if test "$CF_PAGES_BRANCH" = "auth-release"
then
    yarn export:auth
    cp -R apps/auth/out .
else
    yarn export:photos
    cp -R apps/photos/out .
fi
