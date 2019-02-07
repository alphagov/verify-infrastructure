#!/usr/bin/env ash
set -ueo pipefail

: "${BACKEND:?BACKEND not set}"
: "${BACKEND_PORT:?BACKEND_PORT not set}"
: "${BIND_PORT:?BIND_PORT not set}"
: "${RESOLVER:?RESOLVER not set}"

envsubst > /tmp/haproxy.cfg < /tmp/haproxy.cfg.tpl

haproxy -f /tmp/haproxy.cfg
