#!/usr/bin/env bash
set -ueo pipefail

export DEBIAN_FRONTEND=noninteractive

function run-until-success() {
  until $*
  do
    echo "Executing $* failed. Sleeping..."
    sleep 5
  done
}

# remove trust-ad from the options line to prevent prometheus from
# failing when trying to parse this file.
rm /etc/resolv.conf && sed -e 's/ trust-ad//' < /run/systemd/resolve/stub-resolv.conf > /etc/resolv.conf

# Apt
run-until-success apt-get update  --yes
run-until-success apt-get upgrade --yes

# AWS SSM Agent
# Installed by default on Ubuntu Focal AMIs via Snap
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
run-until-success apt-get install --yes chrony
sed '/pool/d' /etc/chrony/chrony.conf \
| cat <(echo "server 169.254.169.123 prefer iburst") - > /tmp/chrony.conf
echo "allow 127/8" >> /tmp/chrony.conf
mv /tmp/chrony.conf /etc/chrony/chrony.conf
systemctl restart chrony

# Docker
echo 'Installing and configuring docker'
mkdir -p /etc/systemd/system/docker.service.d
run-until-success apt-get install --yes docker.io
cat <<EOF > /etc/systemd/system/docker.service.d/override.conf
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd --log-driver awslogs --log-opt awslogs-region=eu-west-2 --log-opt awslogs-group=${cloudwatch_log_group} --dns 10.0.0.2
EOF

# Reload systemctl daemon to pick up new override files
systemctl stop docker
systemctl daemon-reload
systemctl enable --now docker

echo 'Installing prometheus node exporter'
run-until-success apt-get install --yes prometheus-node-exporter
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

echo 'Configuring prometheus EBS'
vol=""
while [ -z "$vol" ]; do
  # adapted from
  # https://medium.com/@moonape1226/mount-aws-ebs-on-ec2-automatically-with-cloud-init-e5e837e5438a
  # [Last accessed on 2020-04-02]
  vol=$(lsblk | grep -e disk | awk '{sub("G","",$4)} {if ($4+0 == ${data_volume_size}) print $1}')
  echo "still waiting for data volume ; sleeping 5"
  sleep 5
done
mkdir -p /srv/prometheus
echo "found volume /dev/$vol"
if [ -z "$(lsblk | grep "$vol" | awk '{print $7}')" ] ; then
  if [ -z "$(blkid /dev/$vol | grep ext4)" ] ; then
    echo "volume /dev/$vol is not formatted ; formatting"
    mkfs -F -t ext4 "/dev/$vol"
  else
    echo "volume /dev/$vol is already formatted"
  fi

  echo "volume /dev/$vol is not mounted ; mounting"
  mount "/dev/$vol" /srv/prometheus
  UUID=$(blkid /dev/$vol -s UUID -o value)
  if [ -z "$(grep $UUID /etc/fstab)" ] ; then
    echo "writing fstab entry"

    echo "UUID=$UUID /srv/prometheus ext4 defaults,nofail 0 2" >> /etc/fstab
  fi
fi

mkdir -p /srv/prometheus/metrics2
chown -R nobody /srv/prometheus

echo 'Installing awscli'
run-until-success apt-get install --yes awscli

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

run-until-success apt-get install --yes moreutils

crontab - <<EOF
$(crontab -l | grep -v 'no crontab')
*/5 * * * * /usr/bin/instance-reboot-required-metric.sh | sponge /var/lib/prometheus/node-exporter/reboot-required.prom
EOF

function run-until-success() {
  until $*
  do
    echo "Executing $* failed. Sleeping..."
    sleep 5
  done
}

# ECS
echo 'Running ECS using Docker'
mkdir -p /etc/ecs
mkdir -p /var/lib/ecs/data

echo 'Installing iptables-persistent'
run-until-success "apt-get install --yes iptables-persistent"

echo 'Adding networking rules for ECS metadata endpoints'
sh -c "echo 'net.ipv4.conf.all.route_localnet = 1' >> /etc/sysctl.conf"
sysctl -p /etc/sysctl.conf
iptables -t nat -A PREROUTING -p tcp -d 169.254.170.2 --dport 80 -j DNAT --to-destination 127.0.0.1:51679
iptables -t nat -A OUTPUT -d 169.254.170.2 -p tcp -m tcp --dport 80 -j REDIRECT --to-ports 51679

echo 'Adding networking rules for CVE-2020-8558'
iptables -I INPUT --dst 127.0.0.0/8 ! --src 127.0.0.0/8 -m conntrack ! --ctstate RELATED,ESTABLISHED,DNAT -j DROP
iptables-save > /etc/iptables/rules.v4

# Have systemd manage the ecs agent
# We have occasionally seen issues where docker gets into a bad
# state. The working hypothesis is that the ecs agent starts
# executing tasks, which include port mappings. When the reboot
# happens at the end of this script it occasionally doesn't tidy
# and recover. So, don't run ECS until after the reboot that we
# know is coming.
cat > /root/pull-ecs-image.sh <<'EOF'
#!/usr/bin/env bash

set -euo pipefail

eval $(aws ecr get-login                                          \
           --no-include-email                                     \
           --region eu-west-2                                     \
           --endpoint-url https://api.ecr.eu-west-2.amazonaws.com \
           --registry-ids ${tools_account_id} \
      )

docker pull ${ecs_agent_image_identifier}
EOF
chmod 0700 /root/pull-ecs-image.sh

cat > /etc/systemd/system/ecs.service <<'EOF'
[Unit]
Description=Elastic Container Service agent
After=docker.service
Wants=docker.service
BindsTo=docker.service

[Service]
TimeoutSec=0
RestartSec=2
Restart=always

ExecStartPre=/bin/mkdir -p /etc/ecs
ExecStartPre=/bin/mkdir -p /var/lib/ecs/data
ExecStartPre=/root/pull-ecs-image.sh
ExecStartPre=-/usr/bin/docker rm --force ecs-agent
ExecStart=/usr/bin/docker run \
  --rm \
  --init \
  --privileged \
  --name ecs-agent \
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
  --env='ECS_AVAILABLE_LOGGING_DRIVERS=["journald", "awslogs"]' \
  --env='ECS_ENABLE_AWSLOGS_EXECUTIONROLE_OVERRIDE=true' \
  --env="ECS_LOGLEVEL=warn" \
  ${ecs_agent_image_identifier}

ExecStop=/usr/bin/docker stop -t 120 ecs-agent

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable ecs

reboot
