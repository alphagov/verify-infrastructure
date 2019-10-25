#!/usr/bin/env ash
set -ueo pipefail

location_blocks="${LOCATION_BLOCKS:?LOCATION_BLOCKS not set}"
location_blocks="$(echo "$location_blocks" | base64 -d)"
export location_blocks

default_log_format="$(cat <<LOGFORMAT | base64
log_format json_event '{ \"@timestamp\": \"\$time_iso8601\", '
                         '\"@message\": \"\$request\", '
                         '\"@fields\": { '
                         '\"remote_addr\": \"\$remote_addr\", '
                         '\"remote_user\": \"\$remote_user\", '
                         '\"body_bytes_sent\": \$body_bytes_sent, '
                         '\"bytes_sent\": \$bytes_sent, '
                         '\"request_time\": \$request_time, '
                         '\"upstream_response_time\": \"\$upstream_response_time\", '
                         '\"upstream_addr\": \"\$upstream_addr\", '
                         '\"upstream_status\": \"\$upstream_status\", '
                         '\"upstream_response_length\": \"\$upstream_response_length\", '
                         '\"upstream_bytes_received\": \"\$upstream_bytes_received\", '
                         '\"upstream_cache_status\": \"\$upstream_cache_status\", '
                         '\"upstream_cookie_name\": \"\$upstream_cookie_name\", '
                         '\"gzip_ratio\": \"\$gzip_ratio\", '
                         '\"sent_http_x_cache\": \"\$sent_http_x_cache\", '
                         '\"sent_http_location\": \"\$sent_http_location\", '
                         '\"http_host\": \"\$http_host\", '
                         '\"server_name\": \"\$server_name\", '
                         '\"server_port\": \"\$server_port\", '
                         '\"status\": \$status, '
                         '\"request\": \"\$request\", '
                         '\"content_type\": \"\$content_type\", '
                         '\"request_method\": \"\$request_method\", '
                         '\"http_referrer\": \"\$http_referer\", '
                         '\"http_user_agent\": \"\$http_user_agent\", '
                         '\"http_x_forwarded_for\": \"\$http_x_forwarded_for\", '
                         '\"ssl_cipher\": \"\$ssl_cipher\", '
                         '\"ssl_protocol\": \"\$ssl_protocol\", '
                         '\"ssl_session_reused\": \"\$ssl_session_reused\", '
                         '\"msec\": \"\$msec\", '
                         '\"connection\": \"\$connection\", '
                         '\"session_id_cookie\": \"\$cookie_x_govuk_session_cookie\", '
                         '\"augur_cookie\": \"\$cookie_augur\", '
                         '\"ssl_client_s_dn\": \"\$ssl_client_s_dn_legacy\", '
                         '\"upstream_cookie_x_govuk_session_cookie\": \"\$upstream_cookie_x_govuk_session_cookie\"'
                         '} }';

access_log /var/log/nginx/access.log json_event;
LOGFORMAT
)"

log_format="${LOG_FORMAT:-$default_log_format}"
log_format="$(echo "$log_format" | base64 -d)"
export log_format

resolver="${RESOLVER:-10.0.0.2}"
export resolver

mkdir -p /tmp/tls

openssl req -x509 \
            -nodes \
            -newkey rsa:2048 \
            -keyout /tmp/tls/key.pem \
            -out    /tmp/tls/cert.pem \
            -days   365 \
            -subj "/C=GB/O=GDS" 2>&1 | {
              message=""
              while read line; do
                message="$message $line"
              done
              echo "{ \"logger_name\": \"openssl\", \"message\": \"$message\" }"
            }

envsubst > /tmp/nginx.conf < /tmp/nginx.conf.tpl


nginx -g 'daemon off;' -c /tmp/nginx.conf
