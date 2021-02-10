FROM ubuntu:18.04

RUN apt update && apt install -y wget gnupg pigz pbzip2 xz-utils lrzip brotli zstd \
	&& wget -qO - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - \
	&& echo "deb http://apt.postgresql.org/pub/repos/apt/ bionic-pgdg main" | tee /etc/apt/sources.list.d/postgresql.list \
	&& apt update && apt install -y postgresql-client \
	&& wget https://dl.minio.io/client/mc/release/linux-amd64/mc -O /sbin/mc && chmod +x /sbin/mc \
	&& apt remove -y wget && apt autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY entrypoint.sh .
ENTRYPOINT ["/entrypoint.sh"]
