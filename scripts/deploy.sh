#!/bin/sh

# This script is run by the Cloudflare Pages integration when deploying the apps
# in this repository. The app to build is decided based on the the value of the
# CF_PAGES_BRANCH environment variable.
#
# Ref: https://developers.cloudflare.com/pages/how-to/build-commands-branches/
#
# The CF Pages configuration is set to use `out/` as the build output directory,
# so once we're done building we symlink `out/` to the app specific output.

set -o errexit
set -o xtrace

if test "$CF_PAGES_BRANCH" = "auth-release"
then
    yarn export:auth
    ln -sf apps/auth/out
else
    yarn export:photos
    ln -sf apps/photos/out
fi
