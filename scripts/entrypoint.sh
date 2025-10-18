#!/bin/bash
set -e

log() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

export HIVE_HOME=${HIVE_HOME:-/opt/hive}
export HIVE_METASTORE_DB_HOST=${HIVE_METASTORE_DB_HOST:-postgres}
export HIVE_METASTORE_DB_PORT=${HIVE_METASTORE_DB_PORT:-5432}
export HIVE_METASTORE_DB_NAME=${HIVE_METASTORE_DB_NAME:-postgres}
export HIVE_METASTORE_DB_USER=${HIVE_METASTORE_DB_USER:-postgres}
export HIVE_METASTORE_DB_PASSWORD=${HIVE_METASTORE_DB_PASSWORD:-postgres}

export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID:-minioadmin}
export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY:-minioadmin}
export S3_ENDPOINT=${S3_ENDPOINT:-http://minio:9000}

log "Waiting for PostgreSQL to be available at ${HIVE_METASTORE_DB_HOST}:${HIVE_METASTORE_DB_PORT}..."
until nc -z ${HIVE_METASTORE_DB_HOST} ${HIVE_METASTORE_DB_PORT}; do
  sleep 2
done
log "PostgreSQL is available."

log "Waiting additional time for PostgreSQL to be fully ready..."
sleep 5

log "Substituting environment variables in hive-site.xml..."
envsubst < ${HIVE_HOME}/conf/hive-site.xml > ${HIVE_HOME}/conf/hive-site.xml.tmp && \
mv ${HIVE_HOME}/conf/hive-site.xml.tmp ${HIVE_HOME}/conf/hive-site.xml
log "Configuration updated successfully."

if [ ! -f "${HIVE_HOME}/.schema_initialized" ]; then
  log "Initializing Hive Metastore schema in PostgreSQL..."
  for i in {1..10}; do
    log "Attempt $i to initialize Hive Metastore schema..."
    if schematool -dbType postgres -initSchema --verbose; then
      log "Schema initialization successful."
      break
    else
      if [ $i -lt 10 ]; then
        log "Schema initialization failed, retrying after 5 seconds..."
        sleep 5
      fi
    fi
  done
  touch "${HIVE_HOME}/.schema_initialized"
fi

log "Starting Hive Metastore service on port 9083..."
exec ${HIVE_HOME}/bin/hive --service metastore
