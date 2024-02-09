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
    # By default, for preview deployments the NEXT_PUBLIC_APP_ENV is set to
    # "test" in the CF environment variables. For production deployments of the
    # auth app, reset this to "production".
    #
    # This is not needed for the default `yarn export:photos` case, because
    # there the actual production deployment runs without NEXT_PUBLIC_APP_ENV
    # being set to anything (and the other preview deployments have
    # NEXT_PUBLIC_APP_ENV set to "test", as is correct).
    export NEXT_PUBLIC_APP_ENV=production
    yarn export:auth
    cp -R apps/auth/out .
else
    yarn export:photos
    cp -R apps/photos/out .
fi
