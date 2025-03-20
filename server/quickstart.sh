#!/bin/sh
#
# Ente self-host quickstart helper script.
#
# Usage:
# sh -c "$(curl -fsSL https://raw.githubusercontent.com/ente-io/ente/HEAD/server/quickstart.sh)"
#
# Docs:
# https://github.com/ente-io/ente/blob/main/server/quickstart/README.md

if test -d my-ente
then
   printf "ERROR: A directory named 'my-ente' already exists.\n"
   printf "       Aborting script to avoid accidentally overwriting user data.\n"
   exit 1
fi

printf "\n - \033[1mH E L L O\033[0m - \033[1;32mE N T E\033[0m -\n\n"

mkdir my-ente && cd my-ente
printf " \033[1;32mE\033[0m   Created directory my-ente\n"

curl -fsSOL https://raw.githubusercontent.com/ente-io/ente/HEAD/server/quickstart/compose.yaml
printf " \033[1;32mN\033[0m   Fetched compose.yaml\n"

touch museum.yaml
printf " \033[1;32mT\033[0m   Created museum.yaml\n"

printf " \033[1;32mE\033[0m   Starting docker compose\n"
printf "\nAfter the cluster has started, open web app at http://localhost:3000\n"
printf "For more details, see https://github.com/ente-io/ente/blob/main/server/quickstart/README.md\n\n"

sleep 1

docker compose up
