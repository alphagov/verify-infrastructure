ARG base_image=nginx:1.17.5-alpine
FROM ${base_image}

EXPOSE 8443
RUN apk add --no-cache gettext openssl

USER www-data
WORKDIR /tmp
COPY --chown=www-data . /tmp


ENTRYPOINT ["/tmp/docker-entrypoint.sh"]
