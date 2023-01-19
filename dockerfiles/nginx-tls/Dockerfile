ARG base_image=nginx:1.17.5-alpine
FROM ${base_image}

EXPOSE 8443

RUN apk add --no-cache gettext openssl

RUN mkdir -p /etc/nginx/ssl \
 && chown -R www-data:www-data /etc/nginx \
 && mkdir -p /var/lib/nginx \
 && chown -R www-data:www-data /var/lib/nginx \
 && mkdir -p /var/log/nginx \
 && chown -R www-data:www-data /var/log/nginx \
 && chown -R www-data:www-data /var/cache/nginx

USER www-data

WORKDIR /tmp

COPY --chown=www-data . /tmp

ENTRYPOINT ["/tmp/docker-entrypoint.sh"]
