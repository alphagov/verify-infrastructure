FROM haproxy:2.0.20-alpine

EXPOSE 4500

RUN apk add --no-cache gettext

WORKDIR /tmp

USER haproxy

COPY . /tmp

ENTRYPOINT ["/tmp/docker-entrypoint.sh"]
