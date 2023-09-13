#!/usr/bin/env bash
#
# export_keycloak.sh

set -o errexit
set -o errtrace
set -o nounset
set -o pipefail

# If something goes wrong, this script does not run forever, but times out
TIMEOUT_SECONDS=300
# Logfile for the keycloak export instance
LOGFILE=/tmp/standalone.sh.log
# destionation export file
JSON_EXPORT_FILE=/data/realms-export-single-file.json

# Remove files from old backups inside the container
# You could also move the files or change the name with timestamp prefix
rm -f ${LOGFILE} ${JSON_EXPORT_FILE}

# Start a new keycloak instance with exporting options enabled.
# Use the port offset argument to prevent port conflicts
# with the "real" keycloak instance.
timeout ${TIMEOUT_SECONDS}s \
    /opt/jboss/keycloak/bin/standalone.sh \
        -Dkeycloak.migration.action=export \
        -Dkeycloak.migration.provider=singleFile \
        -Dkeycloak.migration.file=${JSON_EXPORT_FILE} \
        -Djboss.socket.binding.port-offset=99 \
    > ${LOGFILE} &

# Grab the keycloak export instance process id
PID="${!}"

# Wait for the export to finish
# It will wait till it sees the string, which indicates
# a successful finished backup.
# If it will take too long (>TIMEOUT_SECONDS), it will be stopped.
timeout ${TIMEOUT_SECONDS}s \
    grep -m 1 "Export finished successfully" <(tail -f ${LOGFILE})

# Stop the keycloak export instance
kill ${PID}