ARG base_image=nginx:1.17.5-alpine
FROM ${base_image}

EXPOSE 8443
RUN apk add --no-cache gettext openssl

USER nginx
WORKDIR /tmp
COPY --chown=nginx . /tmp

USER root
ENTRYPOINT ["/tmp/docker-entrypoint.sh"]
