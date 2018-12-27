#!/usr/bin/env bash
set -ueo pipefail

# Apt
mkdir -p /etc/apt/apt.conf.d
if [ -n "${egress_proxy_url_with_protocol}" ]; then
  cat << EOF > /etc/apt/apt.conf.d/egress.conf
Acquire::http::Proxy "${egress_proxy_url_with_protocol}/";
Acquire::https::Proxy "${egress_proxy_url_with_protocol}/";
EOF
fi
apt-get update  --yes
apt-get upgrade --yes

# AWS SSM Agent
# Installed by default on Ubuntu Bionic AMIs via Snap
mkdir -p /etc/systemd/system/snap.amazon-ssm-agent.amazon-ssm-agent.service.d
if [ -n "${egress_proxy_url_with_protocol}" ]; then
cat <<EOF > /etc/systemd/system/snap.amazon-ssm-agent.amazon-ssm-agent.service.d/override.conf
[Service]
Environment="http_proxy=${egress_proxy_url_with_protocol}"
Environment="https_proxy=${egress_proxy_url_with_protocol}"
Environment="no_proxy=169.254.169.254"
EOF
fi
systemctl stop snap.amazon-ssm-agent.amazon-ssm-agent
systemctl daemon-reload
systemctl start snap.amazon-ssm-agent.amazon-ssm-agent

# Use Amazon NTP
apt-get install --yes chrony
sed '/pool/d' /etc/chrony/chrony.conf \
| cat <(echo "server 169.254.169.123 prefer iburst") - > /tmp/chrony.conf
mv /tmp/chrony.conf /etc/chrony/chrony.conf

# Docker
mkdir -p /etc/systemd/system/docker.service.d
apt-get install --yes docker.io
cat <<EOF > /etc/systemd/system/docker.service.d/override.conf
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd --log-driver journald --dns 10.0.0.2
EOF
if [ -n "${egress_proxy_url_with_protocol}" ]; then
cat <<EOF >> /etc/systemd/system/docker.service.d/override.conf
Environment="HTTP_PROXY=${egress_proxy_url_with_protocol}"
Environment="HTTPS_PROXY=${egress_proxy_url_with_protocol}"
EOF
fi

# Reload systemctl daemon to pick up new override files
systemctl stop docker
systemctl daemon-reload
systemctl start docker

mkdir -p /etc/ecs
mkdir -p /var/lib/ecs/data

docker run \
  --init \
  --privileged \
  --name ecs-agent \
  --detach=true \
  --restart=on-failure:10 \
  --volume=/etc/ecs:/etc/ecs \
  --volume=/lib64:/lib64 \
  --volume=/lib:/lib \
  --volume=/proc:/host/proc \
  --volume=/sbin:/sbin \
  --volume=/sys/fs/cgroup:/sys/fs/cgroup \
  --volume=/usr/lib:/usr/lib \
  --volume=/var/lib/ecs/data:/data \
  --volume=/var/lib/ecs/dhclient:/var/lib/dhclient \
  --volume=/var/run:/var/run \
  --net=host \
  --env="ECS_CLUSTER=${cluster}" \
  --env="${ecs_egress_proxy_setting}" \
  --env=AWS_DEFAULT_REGION=eu-west-2 \
  --env="NO_PROXY=169.254.169.254,169.254.170.2,/var/run/docker.sock" \
  --env=ECS_DATADIR=/data \
  --env=ECS_ENABLE_TASK_ENI=true \
  --env=ECS_ENABLE_TASK_IAM_ROLE=true \
  --env=ECS_ENABLE_TASK_IAM_ROLE_NETWORK_HOST=true \
  --env='ECS_AVAILABLE_LOGGING_DRIVERS=["journald"]' \
  amazon/amazon-ecs-agent:v1.23.0
