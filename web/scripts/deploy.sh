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
#
# To test this script locally, run
#
#    CF_PAGES_BRANCH=foo-bar ./scripts/deploy.sh
#

set -o errexit
set -o xtrace

rm -rf out

case "$CF_PAGES_BRANCH" in
    accounts-*)
        yarn build:accounts
        cp -R apps/accounts/out .
        ;;
    auth-*)
        yarn build:auth
        cp -R apps/auth/out .
        ;;
    cast-*)
        yarn build:cast
        cp -R apps/cast/out .
        ;;
    *)
        yarn build:photos
        cp -R apps/photos/out .
        ;;
esac
