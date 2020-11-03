# Postgres S3 docker/kubernetes backup

[![Build status](https://github.com/BackupTools/postgres-backup-s3/workflows/Docker%20Image%20CI/badge.svg)]() [![Pulls](https://img.shields.io/docker/pulls/backuptools/postgres-backup-s3?style=flat&labelColor=1B3D4B&color=06A64F&logoColor=white&logo=docker&label=pulls)]()

Docker image to backup Postgres database to S3 using pg_dump and compress using pigz.

## Advantages/features
- [x] Supports custom S3 endpoints (e.g. minio)
- [x] Uses piping instead of tmp file
- [x] Compression is done with pigz (parallel gzip)
- [x] Creates bucket if it's not created
- [x] Can be run in Kubernetes or Docker
- [ ] TODO: OpenSSL encryption
- [ ] TODO: Add other compression methods
- [ ] TODO: Add other dbs (e.g. postgres, mysql)

## Configuration
```bash
S3_BUCK=postgres1-backups
S3_NAME=folder-name/backup-name-prefix
S3_URI=https://s3-key:s3-secret@s3.host.tld
PG_URI=postgres://mongo-host:5432/db-name
```

Or see `docker-compose.yml` file to run this container with Docker.

## Cron backup with kubernetes

See `kubernetes-cronjob.yml` file.
