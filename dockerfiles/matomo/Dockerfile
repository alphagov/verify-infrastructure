ARG base_image=matomo:3.13.5-fpm-alpine
FROM ${base_image}

RUN sed -i 's/memory_limit.*/memory_limit = 1G/' /usr/local/etc/php/php.ini-*

COPY z-php-fpm-process-manager.conf /usr/local/etc/php-fpm.d/z-php-fmp-process-manager.conf