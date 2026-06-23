#!/bin/bash
set -e
set -o pipefail

# Date function
get_date () {
    date +[%Y-%m-%d\ %H:%M:%S]
}

# Script
: ${GPG_KEYSERVER:=${INPUT_GPG_KEYSERVER:='keyserver.ubuntu.com'}}
: ${GPG_KEYID:=${INPUT_GPG_KEYID:=''}}
: ${COMPRESS:=${INPUT_COMPRESS:='pigz'}}
: ${COMPRESS_LEVEL:=${INPUT_COMPRESS_LEVEL:='9'}}
: ${MAINTENANCE_DB:=${INPUT_MAINTENANCE_DB:='postgres'}}
: ${S3_URI:=${INPUT_S3_URI:=''}}
: ${S3_BUCK:=${INPUT_S3_BUCK:=''}}
: ${S3_NAME:=${INPUT_S3_NAME:=''}}
: ${PG_URI:=${INPUT_PG_URI:=''}}
START_DATE=`date +%Y-%m-%d_%H-%M-%S`

if [ -z "$GPG_KEYID" ]
then
    echo "$(get_date) !WARNING! It's strongly recommended to encrypt your backups."
else
    echo "$(get_date) Preparing keys: importing from keyserver"
    gpg --keyserver ${GPG_KEYSERVER} --recv-keys ${GPG_KEYID}
fi

echo "$(get_date) Postgres backup started"

export MC_HOST_backup=$S3_URI

mc mb backup/${S3_BUCK} --insecure || true

case $COMPRESS in
  'pigz' )
      COMPRESS_CMD='pigz -'${COMPRESS_LEVEL}
      COMPRESS_POSTFIX='.gz'
    ;;
  'xz' )
      COMPRESS_CMD='xz -'${COMPRESS_LEVEL}
      COMPRESS_POSTFIX='.xz'
    ;;
  'bzip2' )
      COMPRESS_CMD='bzip2 -'${COMPRESS_LEVEL}
      COMPRESS_POSTFIX='.bz2'
    ;;
  'lrzip' )
      COMPRESS_CMD='lrzip -l -L5'
      COMPRESS_POSTFIX='.lrz'
    ;;
  'brotli' )
      COMPRESS_CMD='brotli -'${COMPRESS_LEVEL}
      COMPRESS_POSTFIX='.br'
    ;;
  'zstd' )
      COMPRESS_CMD='zstd -'${COMPRESS_LEVEL}
      COMPRESS_POSTFIX='.zst'
    ;;
  * )
      echo "$(get_date) Invalid compression method: $COMPRESS. The following are available: pigz, xz, bzip2, lrzip, brotli, zstd"
      exit 1
    ;;
esac

dump_db(){
  DATABASE=$1
  # Ping databaase
  psql ${PG_URI%/}/${DATABASE} -c ''

  echo "$(get_date) Dumping database: $DATABASE"

  if [ -z "$GPG_KEYID" ]
  then
    pg_dump ${PG_URI%/}/${DATABASE} | $COMPRESS_CMD | mc pipe backup/${S3_BUCK}/${S3_NAME}-${START_DATE}-${DATABASE}.pgdump${COMPRESS_POSTFIX} --insecure
  else
    pg_dump ${PG_URI%/}/${DATABASE} | $COMPRESS_CMD \
    | gpg --encrypt -z 0 --recipient ${GPG_KEYID} --trust-model always \
    | mc pipe backup/${S3_BUCK}/${S3_NAME}-${START_DATE}-${DATABASE}.pgdump${COMPRESS_POSTFIX}.pgp --insecure
  fi
}

DB_NAME=${PG_URI##*/}
if [[ $DB_NAME == *"@"* ]]
then
  DB_NAME=""
fi

if [ -z "$DB_NAME" ]
then
  echo "$(get_date) No database selected. Running backup for all databases:"
  DB_LIST=$(psql ${PG_URI%/}/${MAINTENANCE_DB} -A -c "SELECT datname FROM pg_database WHERE datname NOT LIKE 'template%';" | head -n -1 | tail -n +2)
  for db in $DB_LIST; do
    dump_db "$db"
  done
else
  PG_URI=${PG_URI%$DB_NAME}
  dump_db "$DB_NAME"
fi

echo "$(get_date) Postgres backup completed successfully"
