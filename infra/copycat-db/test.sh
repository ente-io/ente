#!/bin/bash

set -o xtrace
set -o errexit

PROJECT=copycat-db

docker rmi "ente/$PROJECT" || true
docker build --tag "ente/$PROJECT" .

# Interactively run the container.
#
# By passing "$@", we allow any arguments passed to test.sh to be forwarded to
# the image (useful for testing out things, e.g. `./test.sh sh`).
docker run \
    --interactive --tty --rm \
    --env-file copycat-db.env \
    --name "$PROJECT" \
    "ente/$PROJECT" \
    "$@"
