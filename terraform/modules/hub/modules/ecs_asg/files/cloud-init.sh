#!/usr/bin/env bash
set -ueo pipefail

if [ -n "${egress_proxy_url_with_protocol}" ]; then
  sed -i \
      '/\[main\]/a proxy=${egress_proxy_url_with_protocol}' \
      /etc/yum.conf
fi
yum update --assumeyes

mkdir -p /etc/systemd/system/docker.service.d

if [ -n "${egress_proxy_url_with_protocol}" ]; then
cat <<EOF > /etc/systemd/system/docker.service.d/override.conf
[Service]
Environment="HTTP_PROXY=${egress_proxy_url_with_protocol}"
Environment="HTTPS_PROXY=${egress_proxy_url_with_protocol}"
EOF
fi

mkdir -p /etc/systemd/system/amazon-ssm-agent.service.d

if [ -n "${egress_proxy_url_with_protocol}" ]; then
cat <<EOF > /etc/systemd/system/amazon-ssm-agent.service.d/override.conf
[Service]
Environment="http_proxy=${egress_proxy_url_with_protocol}"
Environment="https_proxy=${egress_proxy_url_with_protocol}"
Environment="no_proxy=169.254.169.254"
EOF
fi

# Reload systemctl daemon to pick up new override files
systemctl daemon-reload
systemctl restart docker

logger "Installing and enabling SSM agent"
yum install --assumeyes "https://amazon-ssm-eu-west-2.s3.amazonaws.com/latest/linux_amd64/amazon-ssm-agent.rpm"

mkdir -p /etc/ecs
mkdir -p /data
cat <<ECS > /etc/ecs/ecs.config
ECS_CLUSTER=${cluster}
AWS_DEFAULT_REGION=eu-west-2
ECS_DATADIR=/data
NO_PROXY=169.254.169.254,169.254.170.2,/var/run/docker.sock
${ecs_egress_proxy_setting}
ECS
