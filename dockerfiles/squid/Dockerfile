FROM alpine:3.8

RUN apk add --no-cache squid=3.5.27-r4

RUN    touch /etc/squid/squid.conf \
    && mkdir -p /squid \
    && chown -R squid /etc/squid/squid.conf /squid

EXPOSE 8080

WORKDIR /tmp

USER squid

COPY ./docker-entrypoint.sh /tmp/docker-entrypoint.sh

ENTRYPOINT ["/tmp/docker-entrypoint.sh"]
