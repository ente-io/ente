#!/bin/bash

set -o errexit
set -o xtrace

# Find the name of the latest backup
# The backup file name contains the epoch, so we can just sort.
BACKUP_FILE=$(rclone lsf --include 'db-*.custom' --files-only $RCLONE_DESTINATION | sort | tail -1)

# Download it
rclone copy --log-level INFO "${RCLONE_DESTINATION}${BACKUP_FILE}" .

# Restore from it
#
# This create a database named rdb on Postgres - this is only used for the
# initial connection, the actual ente_db database will be created once the
# restore starts.
#
# Flags:
#
# * no-owner: recreates the schema using the current user, not the one that was
#   used for the export.
#
# * no-privileges: skip the assignment of roles (this way we do not have to
#   recreate all the users from the original database before proceeding with the
#   restore)

createdb rdb || true
pg_restore -d rdb --create --no-privileges --no-owner --exit-on-error "$BACKUP_FILE"

# Delete any tokens that were in the backup
psql -d ente_db -c 'delete from tokens'

# Delete any push tokens that were in the backup
psql -d ente_db -c 'delete from push_tokens'

# Delete some more temporary data that might've come up in the backup
psql -d ente_db -c 'delete from queue'
psql -d ente_db -c 'delete from temp_objects'

set +o xtrace
echo "copycat-db: restore complete: $BACKUP_FILE"
