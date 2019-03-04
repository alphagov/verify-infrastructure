#!/usr/bin/env ash
set -ueo pipefail

: "${BACKEND:?BACKEND not set}"
: "${BACKEND_PORT:?BACKEND_PORT not set}"
: "${BIND_PORT:?BIND_PORT not set}"
: "${RESOLVER:?RESOLVER not set}"

envsubst > /tmp/haproxy.cfg < /tmp/haproxy.cfg.tpl

mkdir -p /tmp/tls

openssl req -x509 \
            -nodes \
            -newkey rsa:2048 \
            -keyout /tmp/tls/key.pem \
            -out    /tmp/tls/cert.pem \
            -days   365 \
            -subj "/C=GB/O=GDS"

cat /tmp/tls/key.pem /tmp/tls/cert.pem > /tmp/tls/chain.pem

echo /tmp/tls/chain.pem

haproxy -f /tmp/haproxy.cfg
