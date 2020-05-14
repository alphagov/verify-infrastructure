FROM haproxy:2.0.14-alpine

EXPOSE 4500

RUN addgroup -S haproxy && \
    adduser  -S -G haproxy haproxy && \
    apk add --no-cache gettext openssl ca-certificates

WORKDIR /tmp

USER haproxy

COPY . /tmp

ENTRYPOINT ["/tmp/docker-entrypoint.sh"]
