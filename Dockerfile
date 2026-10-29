ARG MIERU_VERSION=3.39.0
ARG TARGETARCH=amd64

FROM alpine:3.24 AS downloader
ARG MIERU_VERSION
ARG TARGETARCH
RUN apk add --no-cache ca-certificates wget
WORKDIR /tmp/mita
RUN wget -qO- "https://github.com/enfein/mieru/releases/download/v${MIERU_VERSION}/mita_${MIERU_VERSION}_linux_${TARGETARCH}.tar.gz" | tar xz
WORKDIR /tmp/mieru
RUN wget -qO- "https://github.com/enfein/mieru/releases/download/v${MIERU_VERSION}/mieru_${MIERU_VERSION}_linux_${TARGETARCH}.tar.gz" | tar xz

FROM alpine:3.24
RUN apk add --no-cache ca-certificates tini && \
    adduser -H -D -g "" mita && \
    adduser -H -D -g "" mieru
COPY --from=downloader /tmp/mita/mita /usr/local/bin/mita
COPY --from=downloader /tmp/mieru/mieru /usr/local/bin/mieru
RUN chmod +x /usr/local/bin/mita /usr/local/bin/mieru && \
    mkdir -p /etc/mita /var/lib/mita /var/run/mita \
             /etc/mieru /var/lib/mieru /var/run/mieru /srv && \
    chown -R mita:mita /etc/mita /var/lib/mita /var/run/mita && \
    chown -R mieru:mieru /etc/mieru /var/lib/mieru /var/run/mieru
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["/sbin/tini","--","/usr/local/bin/docker-entrypoint.sh"]
