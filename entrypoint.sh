#!/bin/bash
set -e

# Date function
get_date () {
    date +[%Y-%m-%d\ %H:%M:%S]
}

# Script
echo "$(get_date) Postgres backup started"

export MC_HOST_backup=$S3_URI

mc mb backup/${S3_BUCK} --insecure

pg_dump $PG_URI | pigz -9 | mc pipe backup/${S3_BUCK}/${S3_NAME}-`date +%Y-%m-%d_%H-%M-%S`.pgdump --insecure

echo "$(get_date) Postgres backup completed successfully"
