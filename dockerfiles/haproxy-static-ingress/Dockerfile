FROM haproxy:1.9.0-alpine

RUN addgroup -S haproxy && adduser -S -G haproxy haproxy

WORKDIR /tmp

USER haproxy

COPY . /tmp

ENTRYPOINT ["/tmp/docker-entrypoint.sh"]

COPY haproxy.cfg /usr/local/etc/haproxy/haproxy.cfg
