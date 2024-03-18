#!/bin/sh

# This script is meant to be run on the production instances.
#
# It will pull the latest Docker image, restart the museum process and start
# tailing the logs as a sanity check.

set -o errexit

# The service file also does this, but also pre-pull here to minimize downtime.
sudo docker pull rg.fr-par.scw.cloud/ente/museum-prod

sudo systemctl restart museum
sudo systemctl status museum | more
sudo tail -f /root/var/logs/museum.log
