FROM postgres:18

RUN apt update && apt install -y gnupg pigz pbzip2 xz-utils lrzip brotli zstd \
	&& apt autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY --from=pgsty/mc:RELEASE.2026-10-26T00-00-00Z /usr/bin/mc /usr/local/bin/mc

COPY entrypoint.sh .
ENTRYPOINT ["/entrypoint.sh"]
