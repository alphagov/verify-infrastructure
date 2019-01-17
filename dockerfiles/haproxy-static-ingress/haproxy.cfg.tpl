global
    maxconn 10000
    log stdout local0 warning
    user haproxy
    group haproxy

defaults
    timeout connect 10s
    timeout client 30s
    timeout server 30s
    log global
    option tcplog
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
    mode tcp
    bind *:$PORT
    default_backend alb

backend alb
    mode tcp
    balance roundrobin
    server alb $BACKEND:$PORT resolvers vpcdns check inter 100 fastinter 100
