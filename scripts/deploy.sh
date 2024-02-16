#!/bin/sh

# This script is run by the Cloudflare Pages integration when deploying the apps
# in this repository. The app to build and the environment variables to use is
# decided based on the value of the CF_PAGES_BRANCH environment variable.
#
# The Cloudflare Pages build configuration is set to use `out/` as the build
# output directory, so once we're done building we copy the app specific output
# to `out/` (symlinking didn't work).
#
# Ref: https://developers.cloudflare.com/pages/how-to/build-commands-branches/

set -o errexit
set -o xtrace

rm -rf out

case "$CF_PAGES_BRANCH" in
    accounts-*)
        yarn export:accounts
        cp -R apps/accounts/out .
        ;;
    auth-*)
        yarn export:auth
        cp -R apps/auth/out .
        ;;
    *)
        yarn export:photos
        cp -R apps/photos/out .
        ;;
esac
