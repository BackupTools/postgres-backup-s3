FROM postgres:18

RUN apt update && apt install -y gnupg pigz pbzip2 xz-utils lrzip brotli zstd \
	&& apt autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY --from=minio/mc /usr/bin/mc /usr/local/bin/mc

COPY entrypoint.sh .
ENTRYPOINT ["/entrypoint.sh"]
