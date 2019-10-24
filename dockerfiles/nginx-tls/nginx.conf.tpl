worker_processes  auto;
pid               /tmp/nginx.pid;

events {
  worker_connections  4096;
}

http {
  sendfile     on;
  tcp_nopush   on;
  server_names_hash_bucket_size 128;

  include /etc/nginx/mime.types;
  default_type application/octet-stream;

  resolver     "$resolver";

  $log_format

  server {
    listen       8443 ssl;
    ssl_protocols       TLSv1.2 TLSv1.3;
    ssl_ciphers         ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA384;
    ssl_certificate     /tmp/tls/cert.pem;
    ssl_certificate_key /tmp/tls/key.pem;
    ssl_session_cache   shared:SSL:1m;

    $location_blocks
  }
}

