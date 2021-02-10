#!/bin/bash
set -e
set -o pipefail

# Date function
get_date () {
    date +[%Y-%m-%d\ %H:%M:%S]
}

# Script
: ${GPG_KEYSERVER:='keyserver.ubuntu.com'}
: ${GPG_KEYID:=''}
: ${COMPRESS:='pigz'}
START_DATE=`date +%Y-%m-%d_%H-%M-%S`

if [ -z "$GPG_KEYID" ]
then
    echo "$(get_date) !WARNING! It's strongly recommended to encrypt your backups."
else
    echo "$(get_date) Preparing keys: importing from keyserver"
    gpg --keyserver ${GPG_KEYSERVER} --recv-keys ${GPG_KEYID}
fi

function uri_parser() {
  # uri capture
  uri="$@"

  # safe escaping
  uri="${uri//\`/%60}"
  uri="${uri//\"/%22}"

  # top level parsing
  pattern='^(([a-z]{3,15})://)?((([^:\/]+)(:([^@\/]*))?@)?([^:\/?]+)(:([0-9]+))?)(\/[^?]*)?(\?[^#]*)?(#.*)?$'
  [[ "$uri" =~ $pattern ]] || return 1;

  # component extraction
  uri=${BASH_REMATCH[0]}
  uri_schema=${BASH_REMATCH[2]}
  uri_address=${BASH_REMATCH[3]}
  uri_user=${BASH_REMATCH[5]}
  uri_password=${BASH_REMATCH[7]}
  uri_host=${BASH_REMATCH[8]}
  uri_port=${BASH_REMATCH[10]}
  uri_path=${BASH_REMATCH[11]}
}
# uri_parser $PG_URI ; echo $? $uri_host $uri_user $uri_password $uri_port

echo "$(get_date) Postgres backup started"

export MC_HOST_backup=$S3_URI

mc mb backup/${S3_BUCK} --insecure


case $COMPRESS in
  'pigz' )
      COMPRESS_CMD='pigz -9'
      COMPRESS_POSTFIX='.gz'
    ;;
  'xz' )
      COMPRESS_CMD='xz'
      COMPRESS_POSTFIX='.xz'
    ;;
  'bzip2' )
      COMPRESS_CMD='bzip2 -9'
      COMPRESS_POSTFIX='.bz2'
    ;;
  'lrzip' )
      COMPRESS_CMD='lrzip -l -L5'
      COMPRESS_POSTFIX='.lrz'
    ;;
  'brotli' )
      COMPRESS_CMD='brotli -9'
      COMPRESS_POSTFIX='.br'
    ;;
  'zstd' )
      COMPRESS_CMD='zstd -9'
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
  psql --host=${uri_host} --port=${uri_port} --username=${uri_user} --dbname=${DATABASE} -c ''

  echo "$(get_date) Dumping database: $DATABASE"
  if [ -z "$GPG_KEYID" ]
  then
    # true
    # pg_dump ${PG_URI%/}/${DATABASE} | head -n 10
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

uri_parser $PG_URI
export PGPASSWORD=${uri_password}

if [ -z "$DB_NAME" ]
then
  echo "$(get_date) No specific database selected. Saving each in separate files"
  DB_LIST=$(psql --host=${uri_host} --port=${uri_port} --username=${uri_user} -A -c "SELECT datname FROM pg_database WHERE datname NOT LIKE 'template%';" | head -n -1 | tail -n +2)
  for db in $DB_LIST; do
    dump_db "$db"
  done
else
  PG_URI=${PG_URI%$DB_NAME}
  dump_db "$DB_NAME"
fi

echo "$(get_date) Postgres backup completed successfully"
