global
    ca-base /etc/ssl/certs
    maxconn 10000
    log stdout local0 info
    user haproxy
    group haproxy

defaults
    timeout connect 10s
    timeout client 30s
    timeout server 30s
    log global
    option httplog
    maxconn 10000

resolvers vpcdns
    nameserver vpc ${RESOLVER}
    resolve_retries 3
    timeout resolve 1s
    timeout retry   1s
    hold valid 1s
    hold timeout 0s
    hold nx 0s
    hold other 0s
    hold refused 0s
    hold obsolete 0s

frontend nlb
    mode http
    bind *:$BIND_PORT ssl crt /tmp/tls/chain.pem
    default_backend alb

backend alb
    mode http
    balance roundrobin
    option forwardfor
    http-request add-header x-client-ip %[src]
    http-request add-header hub-forwarded-for %[src]
    server alb $BACKEND:$BACKEND_PORT resolvers vpcdns ssl verify required ca-file ca-certificates.crt check inter 100 fastinter 100
