#!/bin/sh

# This script is run by the Cloudflare Pages integration when deploying the apps
# in this repository. The app to build is decided based on the value of the
# CF_PAGES_BRANCH environment variable.
#
# The Cloudflare Pages build configuration is set to use `out/` as the build
# output directory, so once we're done building we copy the app specific output
# to `out/` (symlinking didn't work).
#
# Ref: https://developers.cloudflare.com/pages/how-to/build-commands-branches/
#
# To test this script locally, run
#
#    CF_PAGES_BRANCH=deploy/foo ./scripts/deploy.sh
#

set -o errexit
set -o xtrace

if test "$(basename $(pwd))" != "web"
then
    echo "ERROR: This script should be run from the web directory"
    exit 1
fi

rm -rf out

case "$CF_PAGES_BRANCH" in
    deploy/accounts)
        yarn build:accounts
        cp -R apps/accounts/out .
        ;;
    deploy/auth)
        yarn build:auth
        cp -R apps/auth/out .
        ;;
    deploy/cast)
        yarn build:cast
        cp -R apps/cast/out .
        ;;
    deploy/photos)
        yarn build:photos
        cp -R apps/photos/out .
        ;;
    *)
        echo "ERROR: We don't know how to build and deploy a branch named $CF_PAGES_BRANCH."
        echo "       Maybe you forgot to add a new case in web/scripts/deploy.sh"
        exit 1
        ;;
esac
