#!/bin/sh

# This script is run by the Cloudflare Pages integration when deploying the apps
# in this repository. The app to build is decided based on the the value of the
# CF_PAGES_BRANCH environment variable.
#
# Ref: https://developers.cloudflare.com/pages/how-to/build-commands-branches/

set -o errexit

if test "$CF_PAGES_BRANCH" == "auth-release"
then
    yarn export:auth
else
    yarn export:photos
fi
