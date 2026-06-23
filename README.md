# Postgres S3 docker/kubernetes backup

[![Build status](https://github.com/BackupTools/postgres-backup-s3/workflows/Docker%20Image%20CI/badge.svg)]() [![Pulls](https://img.shields.io/docker/pulls/backuptools/postgres-backup-s3?style=flat&labelColor=1B3D4B&color=06A64F&logoColor=white&logo=docker&label=pulls)]()

Docker image to backup Postgres database(s) to S3 using pg_dump and compress using pigz(default), xz, bzip2, lrzip, brotli, zstd.

## Advantages/features
- [x] Supports custom S3 endpoints (e.g. minio)
- [x] Uses piping instead of tmp file
- [x] Compression is done with pigz (parallel gzip)
- [x] Creates bucket if it's not created
- [x] Can be run in Kubernetes or Docker
- [x] Backups all databases into separate files, unless specified in the PG_URI
- [x] PGP encryption
- [x] Available `COMPRESS=` methods: pigz, xz, bzip2, lrzip, brotli, zstd
- [x] Ping database before backup
- [x] Github Actions CI/CD
- [ ] TODO: Add other dbs (e.g. postgres, mysql)
- [ ] TODO: Separate definition of HOST, PORT, USERNAME, PASSWORD environment variables as an alternative to PG_URI

## Configuration
```bash
S3_BUCK=postgres1-backups
S3_NAME=folder-name/backup-name-prefix
S3_URI=https://s3-key:s3-secret@s3.host.tld
PG_URI=postgres://mongo-host:5432/db-name
GPG_KEYSERVER=keyserver.ubuntu.com # your hpks keyserver
GPG_KEYID=<key_id> # recipient key, backup will be encrypted if added
COMPRESS=pigz # Available: pigz, xz, bzip2, lrzip, brotli, zstd
COMPRESS_LEVEL=7 # Compression level of desired compression program
```

Or see `docker-compose.yml` file to run this container with Docker.

## Github Actions
```yaml
name: Backup database
on:
  schedule:
    - cron: '0 15 * * *'
  workflow_dispatch: {}

jobs:
  backup-prod:
    runs-on: ubuntu-latest
    steps:
      - name: Create backup
        uses: BackupTools/postgres-backup-s3@master
        with:
          s3_buck: 'backups' # s3 bucket name
          s3_name: 'service-name/db-name' # optionally nested path to store backups
          s3_uri: '${{ secrets.BACKUP_S3_URI }}' # https://s3-key:s3-secret@s3.host.tld
          pg_uri: '${{ secrets.BACKUP_READONLY_URI }}' # postgres://readonly:super-secret@db:5432/postgres
          compress: pigz # Available: pigz, xz, bzip2, lrzip, brotli, zstd

```

## Cron backup with kubernetes

See `kubernetes-cronjob.yml` file.

## Authors & contributors
- [Standart AG, LLC](https://standart.lv/)
- [OPSPRO](https://opspro.eu/)
- [Pavel Khorikov](https://github.com/JargeZ)

## Changelog

[2025-11-01] Updated base docker image. Changed way of installing Minio mc command line tool.
