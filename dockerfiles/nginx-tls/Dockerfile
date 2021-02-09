FROM ghcr.io/alphagov/verify/nginx:1.17.5-alpine

EXPOSE 8443

RUN apk add --no-cache gettext openssl && \
    chown nginx /etc/hosts

WORKDIR /tmp

USER nginx

COPY . /tmp

ENTRYPOINT ["/tmp/docker-entrypoint.sh"]
