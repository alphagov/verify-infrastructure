ARG base_image=matomo:3.13.5-fpm-alpine
FROM ${base_image}

COPY php-memory-limit.ini /usr/local/etc/php/conf.d/

COPY z-php-fpm-process-manager.conf /usr/local/etc/php-fpm.d/z-php-fmp-process-manager.conf