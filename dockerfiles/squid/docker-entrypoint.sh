#!/usr/bin/env ash
set -ueo pipefail

allowlist="${ALLOWLIST:-${WHITELIST:?ALLOWLIST not set}}"
allowlist="$(echo "$allowlist" | base64 -d)"

all_acls=""

for regex in $allowlist; do
all_acls="$(cat <<EOF
$all_acls
acl permitted_dest dstdom_regex ^${regex}$
EOF
)"
done

cat <<EOF > /etc/squid/squid.conf
acl clients src all
${all_acls}

always_direct allow all
http_access   allow clients permitted_dest
http_access   deny all
http_port     0.0.0.0:8080

logformat govuk_verify %tg %6tr %>a %Ss/%03>Hs %<st %rm %ru %[un %Sh/%<a %mt

access_log stdio:/dev/stdout govuk_verify
cache_log  stdio:/dev/stdout govuk_verify

pid_filename /squid/pid
visible_hostname squid
hosts_file /etc/hosts
maximum_object_size 1024 MB
coredump_dir /squid
cache_mem 2048 MB
cache deny all
EOF

# squid -N => no daemon mode
exec squid -N
