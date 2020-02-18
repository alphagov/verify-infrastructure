FROM alpine:3.8

RUN apk add --no-cache squid=3.5.27-r3

RUN    touch /etc/squid/squid.conf \
    && chown squid /etc/squid/squid.conf

EXPOSE 8080

WORKDIR /tmp

USER squid

COPY ./docker-entrypoint.sh /tmp/docker-entrypoint.sh

ENTRYPOINT ["/tmp/docker-entrypoint.sh"]
