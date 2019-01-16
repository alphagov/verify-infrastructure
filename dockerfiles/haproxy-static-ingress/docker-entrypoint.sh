#!/usr/bin/env ash
set -ueo pipefail

backends="${BACKENDS:?BACKENDS not set}"
export backends

envsubst > /tmp/haproxy.cfg < /tmp/haproxy.cfg.tpl

CMD ["haproxy", "-f", "/tmp/haproxy.cfg"]
