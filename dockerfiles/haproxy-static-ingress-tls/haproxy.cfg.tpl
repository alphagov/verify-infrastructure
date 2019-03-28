global
    ca-base /etc/ssl/certs
    maxconn 10000
    log stdout len 65535 format raw local0 info
    user haproxy
    group haproxy

defaults
    timeout connect 10s
    timeout client 30s
    timeout server 30s
    log global
    maxconn 10000
    option persist
    log-format '{"type":"haproxy","timestamp":%Ts,"http_status":%ST,"http_request":"%r","remote_addr":"%ci","bytes_read":%B,"upstream_addr":"%si","backend_name":"%b","retries":%rc,"bytes_uploaded":%U,"upstream_response_time":"%Tr","upstream_connect_time":"%Tc","session_duration":"%Tt","termination_state":"%ts","conc_cons":%fc,"frontend_name":"%f"}'

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

    timeout check   250ms
    timeout connect 250ms

    server alb1 $BACKEND:$BACKEND_PORT resolvers vpcdns ssl verify required ca-file ca-certificates.crt check inter 1000 fastinter 100 downinter 100
    server alb2 $BACKEND:$BACKEND_PORT resolvers vpcdns ssl verify required ca-file ca-certificates.crt check inter 1000 fastinter 100 downinter 100
    server alb3 $BACKEND:$BACKEND_PORT resolvers vpcdns ssl verify required ca-file ca-certificates.crt check inter 1000 fastinter 100 downinter 100
