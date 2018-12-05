FROM nginx:1.15.7-alpine

EXPOSE 8443

RUN apk add --no-cache gettext openssl && \
    ln -sf /dev/stdout /tmp/stdout && \
    ln -sf /dev/stderr /tmp/stderr && \
    chown nginx /etc/hosts

WORKDIR /tmp

USER nginx

COPY . /tmp

ENTRYPOINT ["/tmp/docker-entrypoint.sh"]
