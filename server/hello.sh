#!/bin/sh
#
# Ente self-host quickstart helper script.
#
# Usage:
# sh -c "$(curl -fsSL https://raw.githubusercontent.com/ente-io/ente/HEAD/server/hello.sh)"
#
# Docs:
# https://github.com/ente-io/ente/blob/main/server/quickstart/README.md

if test -d my-ente
then
   printf "ERROR: A directory named 'my-ente' already exists.\n"
   printf "       Aborting script to avoid accidentally overwriting user data.\n"
   exit 1
fi

mkdir my-ente && cd my-ente
printf "E Create directory my-ente\n"

curl -fsSOL https://raw.githubusercontent.com/ente-io/ente/HEAD/server/quickstart/compose.yaml
printf "N Create compose.yaml\n"

touch museum.yaml
printf "T Create museum.yaml\n"

sleep 5 && open "http://localhost:3000" &
printf "E Schedule opening web app (http://localhost:3000) in 5 seconds\n"

sleep 1

docker compose up
