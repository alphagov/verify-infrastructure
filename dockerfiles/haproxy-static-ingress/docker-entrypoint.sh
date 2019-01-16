#!/usr/bin/env ash
set -ueo pipefail

: "${BACKEND:?BACKEND not set}"
: "${PORT:?PORT not set}"
: "${RESOLVER:?RESOLVER not set}"

envsubst > /tmp/haproxy.cfg < /tmp/haproxy.cfg.tpl

haproxy -f /tmp/haproxy.cfg
