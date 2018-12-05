#!/usr/bin/env ash
set -ueo pipefail

location_blocks="${LOCATION_BLOCKS:?LOCATION_BLOCKS not set}"
location_blocks="$(echo "$location_blocks" | base64 -d)"
export location_blocks

resolver="${RESOLVER:-10.0.0.2}"
export resolver

mkdir -p /tmp/tls

openssl req -x509 \
            -nodes \
            -newkey rsa:2048 \
            -keyout /tmp/tls/key.pem \
            -out    /tmp/tls/cert.pem \
            -days   365 \
            -subj "/C=GB/O=GDS"

envsubst > /tmp/nginx.conf < /tmp/nginx.conf.tpl


nginx -g 'daemon off;' -c /tmp/nginx.conf
