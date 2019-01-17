#!/usr/bin/env bash
set -ueo pipefail

CURL="curl --proxy ${egress_proxy_url_with_protocol}"

# Apt
echo 'Configuring apt'
mkdir -p /etc/apt/apt.conf.d
cat << EOF > /etc/apt/apt.conf.d/egress.conf
Acquire::http::Proxy "${egress_proxy_url_with_protocol}/";
Acquire::https::Proxy "${egress_proxy_url_with_protocol}/";
EOF
apt-get update  --yes
apt-get upgrade --yes

# AWS SSM Agent
# Installed by default on Ubuntu Bionic AMIs via Snap
echo 'Configuring AWS SSM'
mkdir -p /etc/systemd/system/snap.amazon-ssm-agent.amazon-ssm-agent.service.d
cat <<EOF > /etc/systemd/system/snap.amazon-ssm-agent.amazon-ssm-agent.service.d/override.conf
[Service]
Environment="http_proxy=${egress_proxy_url_with_protocol}"
Environment="https_proxy=${egress_proxy_url_with_protocol}"
Environment="no_proxy=169.254.169.254"
EOF

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

# Journalbeat for log shipping
echo 'Installing and configuring journalbeat'
(
elastic_beats="artifacts.elastic.co/downloads/beats"
mkdir -p /tmp/journalbeat
cd /tmp/journalbeat

cat <<EOF > journalbeat-6.5.4-amd64.deb.sha512
5c748e2661d16e004606dea4332deb2e990996056e00a54ecbbf691ab3cd33e02d76ce3609fecade326d8fd06e7b3eb328f92de24cd16c8f49ec3c80e14c8ad4  journalbeat-6.5.4-amd64.deb
EOF

$CURL --silent --fail \
      -L -O \
      "https://$elastic_beats/journalbeat/journalbeat-6.5.4-amd64.deb"

sha512sum -c journalbeat-6.5.4-amd64.deb.sha512
dpkg -i journalbeat-6.5.4-amd64.deb
)

cat <<EOF > /etc/journalbeat/journalbeat.yml
journalbeat.inputs:
- paths: []
  seek: cursor

logging.level: warning
logging.to_files: false
logging.to_syslog: true

processors:
- add_cloud_metadata: ~

output.elasticsearch:
  proxy_url: ${egress_proxy_url_with_protocol}
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

echo 'Installing prometheus'
apt-get install --yes prometheus
mkdir -p /etc/systemd/system/prometheus.service.d
cat <<EOF > /etc/systemd/system/prometheus.service.d/override.conf
[Service]
Environment=NO_PROXY=169.254.169.254,localhost,*.${domain},10.0.0.0/16
Environment=HTTP_PROXY=${egress_proxy_url_with_protocol}
Environment=HTTPS_PROXY=${egress_proxy_url_with_protocol}
EOF

systemctl daemon-reload
systemctl enable  prometheus
systemctl restart prometheus

cat <<EOF > /usr/bin/cronitor-prometheus-config-update.sh
#!/usr/bin/env bash
set -ueo pipefail

function cleanup {
  curl -sf -m 10 ${cronitor_prometheus_config_url}/fail
}

trap cleanup ERR

curl -sf -m 10 ${cronitor_prometheus_config_url}/run

aws s3 cp s3://${config_bucket}/prometheus/prometheus.yml /tmp/prometheus.yml

if [ ! $(cmp -s /tmp/prometheus.yml /etc/prometheus/prometheus.yml) ]; then
  mv /tmp/prometheus.yml /etc/prometheus/prometheus.yml
  systemctl reload prometheus
fi

curl -sf -m 10 ${cronitor_prometheus_config_url}/complete
EOF
chmod +x /usr/bin/cronitor-prometheus-config-update.sh

cat <<EOF | crontab -
$(crontab -l | grep -v 'no crontab')
* * * * * /usr/bin/cronitor-prometheus-config-update.sh
EOF
