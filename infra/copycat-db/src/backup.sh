#!/bin/bash

set -o errexit
set -o xtrace

NOWS="$(date +%s)"
BACKUP_FILE="db-$NOWS.custom"

# Scaleway backup names cannot contain dots
BACKUP_NAME="db-$NOWS-custom"

# Calculate an expiry time 1 month from now
EXPIRYS="$(( 30 * 24 * 60 * 60 + $NOWS ))"

# Convert it to the ISO 8601 format that SCW CLI understands
# Note that GNU date uses "-d" and an "@" to pass an epoch (macOS uses "-r").
EXPIRY="$(date -Iseconds --utc --date "@$EXPIRYS")"

if test -z "$SCW_RDB_INSTANCE_ID"
then
    # A required SCW related environment variable hasn't been specified. This is
    # expected when running the script locally for testing. Fallback to using
    # pg_dump for creating the backup.
    pg_dump -Fc ente_db > $BACKUP_FILE
else
    # We need to export a backup first after creating it, before it can be
    # downloaded.
    #
    # Further, our backups currently take longer than the default 20 minute
    # timeout for the export set by Scaleway, and end up failing:
    #
    #     {"error":"scaleway-sdk-go: waiting for database backup failed: timeout after 20m0s"}
    #
    # To avoid this we need to add a custom wait here ourselves instead of using
    # the convenience `--wait` flag for the export command provided by Scaleway.
    BACKUP_ID=$(scw rdb backup create instance-id=$SCW_RDB_INSTANCE_ID \
        name=$BACKUP_NAME expires-at=$EXPIRY \
        database-name=ente_db -o json | jq -r '.id')
    scw rdb backup wait $BACKUP_ID timeout=8h
    scw rdb backup download output=$BACKUP_FILE \
        $(scw rdb backup export $BACKUP_ID --wait -o json | jq -r '.id')
fi

rclone copy --log-level INFO $BACKUP_FILE $RCLONE_DESTINATION

# Delete older backups
rclone delete --log-level INFO --min-age 30d $RCLONE_DESTINATION

set +o xtrace
echo "copycat-db: backup complete: $BACKUP_FILE"
