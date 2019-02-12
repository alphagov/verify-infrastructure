#!/usr/bin/env bash
set -ueo pipefail

export DEBIAN_FRONTEND=noninteractive

# Apt
apt-get update  --yes
apt-get upgrade --yes

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

# Use Amazon NTP
echo 'Installing and configuring chrony'
apt-get install --yes chrony
sed '/pool/d' /etc/chrony/chrony.conf \
| cat <(echo "server 169.254.169.123 prefer iburst") - > /tmp/chrony.conf
mv /tmp/chrony.conf /etc/chrony/chrony.conf

# Docker
echo 'Installing and configuring docker'
mkdir -p /etc/systemd/system/docker.service.d
apt-get install --yes docker.io
cat <<EOF > /etc/systemd/system/docker.service.d/override.conf
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd --log-driver journald --dns 10.0.0.2
EOF

# Reload systemctl daemon to pick up new override files
systemctl stop docker
systemctl daemon-reload
systemctl start docker

# Journalbeat for log shipping
echo 'Installing and configuring journalbeat'
(
elastic_beats="artifacts.elastic.co/downloads/beats"
mkdir -p /tmp/journalbeat
cd /tmp/journalbeat

cat <<EOF > journalbeat-6.6.0-amd64.deb.sha512
a40b695a125a2ed333a776844eccb4519152ceafb3dc0e31bb002720671f9a1344dde1b319fb7242bfde3ba2ff2a838e0b37fbd128f690018c6fb7bd63e8c451  journalbeat-6.6.0-amd64.deb
EOF

curl --silent --fail \
     -L -O \
     "https://$elastic_beats/journalbeat/journalbeat-6.6.0-amd64.deb"

sha512sum -c journalbeat-6.6.0-amd64.deb.sha512
dpkg -i journalbeat-6.6.0-amd64.deb
)

cat <<EOF > /etc/journalbeat/journalbeat.yml
http.enabled: true

journalbeat.inputs:
- paths: []
  seek: cursor

logging.to_files: false
logging.to_syslog: true

processors:
- add_cloud_metadata: ~

output.elasticsearch:
  hosts: ["https://${logit_elasticsearch_url}:443"]
  headers:
    Apikey: ${logit_api_key}
EOF
systemctl restart journalbeat

echo 'Installing prometheus node exporter'
apt-get install --yes prometheus-node-exporter
systemctl enable prometheus-node-exporter
systemctl start prometheus-node-exporter

echo 'Configuring prometheus EBS'
vol="nvme1n1"
mkdir -p /var/lib/prometheus
while true; do
  lsblk | grep -q "$vol" && break
  echo "still waiting for volume /dev/$vol ; sleeping 5"
  sleep 5
done
echo "found volume /dev/$vol"
if [ -z "$(lsblk | grep "$vol" | awk '{print $7}')" ] ; then
  if file -s "/dev/$vol" | grep -q ": data" ; then
    echo "volume /dev/$vol is not formatted ; formatting"
    mkfs -F -t ext4   "/dev/$vol"
  fi
  echo "volume /dev/$vol is formatted"

  if [ -z "$(lsblk | grep "$vol" | awk '{print $7}')" ] ; then
    echo "volume /dev/$vol is not mounted ; mounting"
    mount "/dev/$vol" /var/lib/prometheus
  fi
    echo "volume /dev/$vol is mounted ; mounting"

  if grep -qv "/dev/$vol" /etc/fstab ; then
    echo "/dev/$vol /var/lib/prometheus ext4 defaults,nofail 0 2" >> /etc/fstab
  fi
fi

chown -R nobody /var/lib/prometheus

echo 'Installing awscli'
apt-get install --yes awscli

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

apt-get install --yes moreutils

crontab - <<EOF
$(crontab -l | grep -v 'no crontab')
*/5 * * * * /usr/bin/instance-reboot-required-metric.sh | sponge /var/lib/prometheus/node-exporter/reboot-required.prom
*/5 * * * * /usr/sbin/service journalbeat restart
EOF

# ECS
echo 'Running ECS using Docker'
mkdir -p /etc/ecs
mkdir -p /var/lib/ecs/data

eval $(aws ecr get-login                                          \
           --no-include-email                                     \
           --region eu-west-2                                     \
           --endpoint-url https://api.ecr.eu-west-2.amazonaws.com \
           --registry-ids ${tools_account_id}\
      )

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
  --env=AWS_DEFAULT_REGION=eu-west-2 \
  --env=ECS_DATADIR=/data \
  --env=ECS_ENABLE_TASK_ENI=true \
  --env=ECS_ENABLE_TASK_IAM_ROLE=true \
  --env=ECS_ENABLE_TASK_IAM_ROLE_NETWORK_HOST=true \
  --env='ECS_AVAILABLE_LOGGING_DRIVERS=["journald"]' \
  --env="ECS_LOGLEVEL=warn" \
  ${ecs_agent_image_and_tag}
