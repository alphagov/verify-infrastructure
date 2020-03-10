#!/usr/bin/env bash
set -ueo pipefail

export DEBIAN_FRONTEND=noninteractive

function wait-for-lock() {
	lock_file=$1
	while fuser "$lock_file" >/dev/null 2>&1 ; do
		echo "Waiting for $lock_file to be released..."
		sleep 3
	done
}

function apt-get-wait() {
  status=1
  for (( retry=0; retry<6 && status!=0; retry++ ))
  do
    if (( retry>0 ))
    then
      echo "Identifying who owns the lock and/or lock-frontend."
      lsof /var/lib/dpkg/lock
      lsof /var/lib/dpkg/lock-frontend
      echo "Reattempting to execute apt-get $* $retry times."
    fi;
    wait-for-lock /var/lib/dpkg/lock
    wait-for-lock /var/lib/dpkg/lock-frontend
    apt-get "$@"
    status=$?
  done
  if [ $status != 0 ]; then
    echo "Failed to execute apt-get $*. Exiting the script."
    exit 1;
  fi
}

CURL="curl"
if [ -n "${egress_proxy_url_with_protocol}" ]; then
  CURL="curl --proxy ${egress_proxy_url_with_protocol}"
fi

# Apt
echo 'Configuring apt'
mkdir -p /etc/apt/apt.conf.d
if [ -n "${egress_proxy_url_with_protocol}" ]; then
  cat << EOF > /etc/apt/apt.conf.d/egress.conf
Acquire::http::Proxy "${egress_proxy_url_with_protocol}/";
Acquire::https::Proxy "${egress_proxy_url_with_protocol}/";
EOF
fi
apt-get-wait update --yes
apt-get-wait dist-upgrade --yes

# AWS SSM Agent
# Installed by default on Ubuntu Bionic AMIs via Snap
echo 'Configuring AWS SSM'
mkdir -p /etc/amazon/ssm
cat <<EOF > /etc/amazon/ssm/seelog.xml
<seelog type="adaptive" mininterval="2000000" maxinterval="100000000" critmsgcount="500" minlevel="warn">
    <exceptions>
        <exception filepattern="test*" minlevel="error"/>
    </exceptions>
    <outputs formatid="fmtinfo">
        <console formatid="fmtinfo"/>
    </outputs>
    <formats>
        <format id="fmterror" format="%Date %Time %LEVEL [%FuncShort @ %File.%Line] %Msg%n"/>
        <format id="fmtdebug" format="%Date %Time %LEVEL [%FuncShort @ %File.%Line] %Msg%n"/>
    </formats>
</seelog>
EOF
systemctl stop snap.amazon-ssm-agent.amazon-ssm-agent
systemctl daemon-reload
systemctl start snap.amazon-ssm-agent.amazon-ssm-agent

# We want to make sure that the journal does not write to syslog
# This would fill up the disk, with logs we already have in the journal
echo "Ensure journal does not write to syslog"
mkdir -p /etc/systemd/journald.conf.d/
cat <<JOURNAL > /etc/systemd/journald.conf.d/override.conf
[Journal]
SystemMaxUse=2G
RuntimeMaxUse=2G
ForwardToSyslog=no
ForwardToWall=no
JOURNAL

systemctl daemon-reload
systemctl restart systemd-journald

# Use Amazon NTP
echo 'Installing and configuring chrony'
apt-get-wait install --yes chrony
sed '/pool/d' /etc/chrony/chrony.conf \
| cat <(echo "server 169.254.169.123 prefer iburst") - > /tmp/chrony.conf
echo "allow 127/8" >> /tmp/chrony.conf
mv /tmp/chrony.conf /etc/chrony/chrony.conf
systemctl restart chrony

# Docker
echo 'Installing and configuring docker'
mkdir -p /etc/systemd/system/docker.service.d
apt-get-wait install --yes docker.io
cat <<EOF > /etc/systemd/system/docker.service.d/override.conf
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd --log-driver journald --dns 10.0.0.2
EOF

# Reload systemctl daemon to pick up new override files
systemctl stop docker
systemctl daemon-reload
systemctl enable --now docker

# Journalbeat for log shipping
echo 'Installing and configuring journalbeat'
(
elastic_beats="artifacts.elastic.co/downloads/beats"
mkdir -p /tmp/journalbeat
cd /tmp/journalbeat

cat <<EOF > journalbeat-oss-6.8.3-amd64.deb.sha512
685e571638a3422e8b1c6f6aa7c15db8bf8fa9b91ecfedb4ce7c26dedc418e90b558a37711af2a547cb5025de17361d2fed1042be2d0871d22ec78037f7225a6  journalbeat-oss-6.8.3-amd64.deb
EOF

$CURL --silent --fail \
      -L -O \
      "https://$elastic_beats/journalbeat/journalbeat-oss-6.8.3-amd64.deb"

sha512sum -c journalbeat-oss-6.8.3-amd64.deb.sha512
dpkg -i journalbeat-oss-6.8.3-amd64.deb
)

cat <<EOF > /etc/journalbeat/journalbeat.yml
http.enabled: true

journalbeat.inputs:
- paths: []
  seek: cursor

logging.level: warning
logging.to_files: false
logging.to_syslog: true
logging.json: true

processors:
- add_cloud_metadata: ~
- add_docker_metadata: ~
- decode_json_fields:
    fields: ["message"]
    process_array: false
    max_depth: 1
    target: "log"
    overwrite_keys: false

output.elasticsearch:
  ${journalbeat_egress_proxy_setting}
  hosts: ["https://${logit_elasticsearch_url}:443"]
  headers:
    Apikey: ${logit_api_key}
EOF
# It seems that journalbeat is very unhappy if docker isn't running
# when it starts, so let's update the systemd unit to reflect that
sed -i -e 's/Wants=.*/& docker.service/' /lib/systemd/system/journalbeat.service
sed -i -e 's/After=.*/& docker.service/' /lib/systemd/system/journalbeat.service
systemctl enable --now journalbeat

# ECS
echo 'Installing awscli and iptables-persistent'
apt-get-wait install --yes awscli iptables-persistent

echo 'Adding networking rules for ECS metadata endpoints'
sh -c "echo 'net.ipv4.conf.all.route_localnet = 1' >> /etc/sysctl.conf"
sysctl -p /etc/sysctl.conf
iptables -t nat -A PREROUTING -p tcp -d 169.254.170.2 --dport 80 -j DNAT --to-destination 127.0.0.1:51679
iptables -t nat -A OUTPUT -d 169.254.170.2 -p tcp -m tcp --dport 80 -j REDIRECT --to-ports 51679
iptables-save > /etc/iptables/rules.v4

eval $(aws ecr get-login                                          \
           --no-include-email                                     \
           --region eu-west-2                                     \
           --endpoint-url https://api.ecr.eu-west-2.amazonaws.com \
           --registry-ids ${tools_account_id}\
      )

echo 'Running ECS using Docker'
mkdir -p /etc/ecs
mkdir -p /var/lib/ecs/data
docker run \
  --init \
  --privileged \
  --name ecs-agent \
  --detach=true \
  --restart=always \
  --volume=/etc/ecs:/etc/ecs \
  --volume=/lib64:/lib64 \
  --volume=/lib:/lib \
  --volume=/proc:/host/proc \
  --volume=/sbin:/host/sbin \
  --volume=/sys/fs/cgroup:/sys/fs/cgroup \
  --volume=/usr/lib:/usr/lib \
  --volume=/var/lib/ecs/data:/data \
  --volume=/var/lib/ecs/dhclient:/var/lib/dhclient \
  --volume=/var/run:/var/run \
  --net=host \
  --env="ECS_CLUSTER=${cluster}" \
  --env=AWS_DEFAULT_REGION=eu-west-2 \
  --env=ECS_DATADIR=/data \
  --env=ECS_ENABLE_TASK_ENI=true \
  --env=ECS_ENABLE_TASK_IAM_ROLE=true \
  --env=ECS_ENABLE_TASK_IAM_ROLE_NETWORK_HOST=true \
  --env='ECS_AVAILABLE_LOGGING_DRIVERS=["journald"]' \
  --env="ECS_LOGLEVEL=warn" \
  ${ecs_agent_image_identifier}

apt-get-wait install --yes prometheus-node-exporter
mkdir /etc/systemd/system/prometheus-node-exporter.service.d
# Create an environment file for prometheus node exporter
cat >  /etc/systemd/system/prometheus-node-exporter.service.d/prometheus-node-exporter.env <<EOF
ARGS="--collector.ntp --collector.diskstats.ignored-devices=^(ram|loop|fd|(h|s|v|xv)d[a-z]|nvme\\d+n\\d+p)\\d+$ --collector.filesystem.ignored-mount-points=^/(sys|proc|dev|run|var/lib/docker)($|/) --collector.netdev.ignored-devices=^lo$ --collector.textfile.directory=/var/lib/prometheus/node-exporter"
EOF
# Create an override file which will override prometheus node exporter service file
cat > /etc/systemd/system/prometheus-node-exporter.service.d/10-override-args.conf <<EOF
[Service]
EnvironmentFile=/etc/systemd/system/prometheus-node-exporter.service.d/prometheus-node-exporter.env
EOF
systemctl daemon-reload
systemctl enable prometheus-node-exporter
systemctl restart prometheus-node-exporter

#Initialise a node_creation_time metric to enable the predict_linear function to handle new nodes
echo "node_creation_time `date +%s`" > /var/lib/prometheus/node-exporter/node-creation-time.prom

cat <<EOF > /usr/bin/instance-reboot-required-metric.sh
#!/usr/bin/env bash

echo '# HELP node_reboot_required Node reboot is required for software updates.'
echo '# TYPE node_reboot_required gauge'
if [[ -f '/run/reboot-required' ]] ; then
  echo 'node_reboot_required 1'
else
  echo 'node_reboot_required 0'
fi
EOF

chmod +x /usr/bin/instance-reboot-required-metric.sh

apt-get-wait install --yes moreutils

crontab - <<EOF
$(crontab -l | grep -v 'no crontab')
*/5 * * * * /usr/bin/instance-reboot-required-metric.sh | sponge /var/lib/prometheus/node-exporter/reboot-required.prom
EOF

reboot
