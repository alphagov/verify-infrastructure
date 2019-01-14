resource "aws_security_group" "prometheus" {
  name        = "${var.deployment}-prometheus"
  description = "${var.deployment}-prometheus"

  vpc_id = "${aws_vpc.hub.id}"
}

module "prometheus_can_talk_to_prometheus" {
  source = "modules/microservice_connection"

  source_sg_id      = "${aws_security_group.prometheus.id}"
  destination_sg_id = "${aws_security_group.prometheus.id}"

  port = 9090
}

module "prometheus_can_talk_to_prometheus_node_exporter" {
  source = "modules/microservice_connection"

  source_sg_id      = "${aws_security_group.prometheus.id}"
  destination_sg_id = "${aws_security_group.prometheus.id}"

  port = 9100
}

module "prometheus_can_talk_to_egress_proxy_node_exporter" {
  source = "modules/microservice_connection"

  source_sg_id      = "${aws_security_group.prometheus.id}"
  destination_sg_id = "${module.egress_proxy_ecs_asg.instance_sg_id}"

  port = 9100
}

module "prometheus_can_talk_to_policy" {
  source = "modules/microservice_connection"

  source_sg_id      = "${aws_security_group.prometheus.id}"
  destination_sg_id = "${module.policy_ecs_asg.instance_sg_id}"

  port = 8443
}

resource "aws_iam_role" "prometheus" {
  name = "${var.deployment}-prometheus"

  assume_role_policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "ec2.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
  }
  EOF

  tags = {
    Deployment = "${var.deployment}"
  }
}

resource "aws_iam_instance_profile" "prometheus" {
  name = "${var.deployment}-prometheus"
  role = "${aws_iam_role.prometheus.name}"
}

resource "aws_iam_policy" "prometheus" {
  name        = "${var.deployment}-prometheus"
  description = "${var.deployment}-prometheus"

  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:PutLogEvents"
        ],
        "Resource": [
          "arn:aws:logs::${data.aws_caller_identity.account.account_id}:${var.deployment}-prometheus",
          "arn:aws:logs::${data.aws_caller_identity.account.account_id}:${var.deployment}-prometheus:*"
        ]
      },
      {
        "Effect": "Allow",
        "Action": [
          "ssm:ListAssociations",
          "ssm:UpdateInstanceInformation",
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel",
          "ec2messages:AcknowledgeMessage",
          "ec2messages:DeleteMessage",
          "ec2messages:FailMessage",
          "ec2messages:GetEndpoint",
          "ec2messages:GetMessages",
          "ec2messages:SendReply"
        ],
        "Resource": "*"
      },
      {
        "Effect": "Allow",
        "Action": [
          "s3:GetEncryptionConfiguration",
          "ecs:DiscoverPollEndpoint",
          "ecs:StartTelemetrySession",
          "ecs:Poll",
          "ecs:Submit*"
        ],
        "Resource": "*"
      },
      {
        "Effect": "Allow",
        "Action": [
          "ec2:DescribeInstances"
        ],
        "Resource": "*"
      }
    ]
  }
  EOF
}

resource "aws_iam_role_policy_attachment" "prometheus" {
  role       = "${aws_iam_role.prometheus.name}"
  policy_arn = "${aws_iam_policy.prometheus.arn}"
}

data "template_file" "prometheus_cloud_init" {
  template = "${file("${path.module}/files/cloud-init/prometheus.sh")}"

  vars {
    deployment                       = "${var.deployment}"
    domain                           = "${local.root_domain}"
    egress_proxy_url_with_protocol   = "${local.egress_proxy_url_with_protocol}"
    logit_elasticsearch_url          = "${var.logit_elasticsearch_url}"
    logit_api_key                    = "${var.logit_api_key}"
  }
}

resource "aws_instance" "prometheus" {
  count = "${var.number_of_availability_zones}"

  ami                  = "${data.aws_ami.ubuntu_bionic.id}"
  instance_type        = "t3.medium"
  subnet_id            = "${element(aws_subnet.internal.*.id, count.index)}"
  iam_instance_profile = "${aws_iam_instance_profile.prometheus.name}"
  user_data            = "${data.template_file.prometheus_cloud_init.rendered}"

  vpc_security_group_ids = [
    "${aws_security_group.prometheus.id}",
    "${aws_security_group.scraped_by_prometheus.id}",
    "${aws_security_group.egress_via_proxy.id}",
  ]

  root_block_device {
    volume_size = 20
  }

  tags {
    Name       = "${var.deployment}-prometheus"
    Deployment = "${var.deployment}"
  }
}

resource "aws_ebs_volume" "prometheus" {
  count = "${var.number_of_availability_zones}"

  size      = 100
  encrypted = true

  availability_zone = "${element(
    aws_subnet.internal.*.availability_zone, count.index
  )}"

  tags = {
    Name       = "${var.deployment}-prometheus"
    Deployment = "${var.deployment}"
  }
}

resource "aws_volume_attachment" "prometheus_prometheus" {
  count = "${var.number_of_availability_zones}"

  device_name = "/dev/xvdp"
  volume_id   = "${element(aws_ebs_volume.prometheus.*.id, count.index)}"
  instance_id = "${element(aws_instance.prometheus.*.id, count.index)}"
}

resource "aws_lb_target_group" "prometheus" {
  name                 = "${var.deployment}-prometheus"
  port                 = 9090
  protocol             = "HTTP"
  vpc_id               = "${aws_vpc.hub.id}"

  health_check {
    path     = "/metrics"
    protocol = "HTTP"
    interval = 10
    timeout  = 5
  }
}

resource "aws_lb_target_group_attachment" "prometheus" {
  count = 1

  target_group_arn = "${aws_lb_target_group.prometheus.arn}"
  target_id        = "${element(aws_instance.prometheus.*.id, count.index)}"
  port             = 9090
}
