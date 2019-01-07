FROM haproxy:1.9.0-alpine

RUN addgroup -S haproxy && adduser -S -G haproxy haproxy

COPY haproxy.cfg /usr/local/etc/haproxy/haproxy.cfg
