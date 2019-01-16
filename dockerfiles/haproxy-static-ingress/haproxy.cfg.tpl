global
    maxconn 10000
    log stdout local0 info
    user haproxy
    group haproxy

defaults
    timeout connect 10s
    timeout client 30s
    timeout server 30s
    log global
    option tcplog
    maxconn 10000

frontend nlb
    bind *:4500
    default_backend alb

backend alb
    balance roundrobin
    default-server check maxconn 200
    $BACKENDS
