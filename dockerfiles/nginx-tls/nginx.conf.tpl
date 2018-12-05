worker_processes  5;
error_log         /tmp/sterr;
pid               /tmp/nginx.pid;

events {
  worker_connections  4096;
}

http {
  access_log   /tmp/stdout;
  sendfile     on;
  tcp_nopush   on;
  server_names_hash_bucket_size 128;
  resolver     "$resolver";

  server {
    listen       8443 ssl;
    ssl_protocols       TLSv1.1 TLSv1.2;
    ssl_ciphers         ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128:AES256:HIGH:DES-CBC3-SHA:!aNULL:!eNULL:!EXPORT:!DES:!MD5:!PSK:!RC4:!kEDH;
    ssl_certificate     /tmp/tls/cert.pem;
    ssl_certificate_key /tmp/tls/key.pem;
    ssl_session_cache   shared:SSL:1m;
    ssl_session_timeout 1m;

    $location_blocks
  }
}

