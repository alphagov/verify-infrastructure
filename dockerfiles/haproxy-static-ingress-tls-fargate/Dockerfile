ARG base_image=haproxy:2.0.14-alpine
FROM ${base_image}

EXPOSE 4500

RUN apk add --no-cache gettext openssl ca-certificates

WORKDIR /tmp

USER haproxy

COPY . /tmp

ENTRYPOINT ["/tmp/docker-entrypoint.sh"]
