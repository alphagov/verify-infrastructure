# This is for colocating exporters as ECS DAEMON tasks with Prometheus
resource "aws_ecs_cluster" "prometheus" {
  name = "${var.deployment}-prometheus"
}

resource "aws_security_group" "prometheus" {
  name        = "${var.deployment}-prometheus"
  description = "${var.deployment}-prometheus"

  vpc_id = aws_vpc.hub.id
}

resource "aws_security_group_rule" "prometheus_egress_to_internet_over_http" {
  type      = "egress"
  protocol  = "tcp"
  from_port = 80
  to_port   = 80

  security_group_id = aws_security_group.prometheus.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "prometheus_egress_to_internet_over_https" {
  type      = "egress"
  protocol  = "tcp"
  from_port = 443
  to_port   = 443

  security_group_id = aws_security_group.prometheus.id
  cidr_blocks       = ["0.0.0.0/0"]
}

module "prometheus_can_talk_to_prometheus" {
  source = "./modules/microservice_connection"

  source_sg_id      = aws_security_group.prometheus.id
  destination_sg_id = aws_security_group.prometheus.id

  port = 9090
}

module "prometheus_can_talk_to_prometheus_node_exporter" {
  source = "./modules/microservice_connection"

  source_sg_id      = aws_security_group.prometheus.id
  destination_sg_id = aws_security_group.prometheus.id

  port = 9100
}

module "prometheus_can_talk_to_egress_proxy_node_exporter" {
  source = "./modules/microservice_connection"

  source_sg_id      = aws_security_group.prometheus.id
  destination_sg_id = module.egress_proxy_ecs_asg.instance_sg_id

  port = 9100
}

module "prometheus_can_talk_to_prometheus_beat_exporter" {
  source = "./modules/microservice_connection"

  source_sg_id      = aws_security_group.prometheus.id
  destination_sg_id = aws_security_group.prometheus.id

  port = 9479
}

module "prometheus_can_talk_to_egress_proxy_beat_exporter" {
  source = "./modules/microservice_connection"

  source_sg_id      = aws_security_group.prometheus.id
  destination_sg_id = module.egress_proxy_ecs_asg.instance_sg_id

  port = 9479
}

module "prometheus_can_talk_to_frontend_task" {
  source = "./modules/microservice_connection"

  source_sg_id      = aws_security_group.prometheus.id
  destination_sg_id = aws_security_group.frontend_task.id

  port = 8443
}

module "prometheus_can_talk_to_hub_fargate_microservices" {
  source = "./modules/microservice_connection"

  source_sg_id      = aws_security_group.prometheus.id
  destination_sg_id = aws_security_group.hub_fargate_microservice.id

  port = 8443
}

module "prometheus_can_talk_to_ingress_for_scraping_metadata" {
  source = "./modules/microservice_connection"

  source_sg_id      = aws_security_group.prometheus.id
  destination_sg_id = aws_security_group.ingress.id
}

module "prometheus_can_talk_to_cloudwatch_vpc_endpoint" {
  source = "./modules/microservice_connection"

  source_sg_id      = aws_security_group.prometheus.id
  destination_sg_id = aws_security_group.cloudwatch_vpc_endpoint.id
}

resource "aws_security_group_rule" "prometheus_can_pull_config_from_s3" {
  type      = "egress"
  protocol  = "tcp"
  from_port = 443
  to_port   = 443

  security_group_id = aws_security_group.prometheus.id
  prefix_list_ids   = [aws_vpc_endpoint.s3.prefix_list_id]
}

resource "aws_security_group" "scraped_by_prometheus" {
  name        = "${var.deployment}-scraped-by-prometheus"
  description = "${var.deployment}-scraped-by-prometheus"

  vpc_id = aws_vpc.hub.id
}

module "scraped_by_prometheus_can_be_scraped_by_prometheus" {
  source = "./modules/microservice_connection"

  source_sg_id      = aws_security_group.prometheus.id
  destination_sg_id = aws_security_group.scraped_by_prometheus.id

  port = 9100
}

module "scraped_by_prometheus_beat_can_be_scraped_by_prometheus" {
  source = "./modules/microservice_connection"

  source_sg_id      = aws_security_group.prometheus.id
  destination_sg_id = aws_security_group.scraped_by_prometheus.id

  port = 9479
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
    Deployment = var.deployment
  }
}

resource "aws_iam_instance_profile" "prometheus" {
  name = "${var.deployment}-prometheus"
  role = aws_iam_role.prometheus.name
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
          "arn:aws:logs::${data.aws_caller_identity.account.account_id}:${var.deployment}-hub",
          "arn:aws:logs::${data.aws_caller_identity.account.account_id}:${var.deployment}-hub:*",
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
          "cloudwatch:Describe*",
          "cloudwatch:Get*",
          "cloudwatch:List*"
        ],
        "Resource": "*"
      },
      {
        "Effect": "Allow",
        "Action": [
          "ecs:RegisterContainerInstance",
          "ecs:DeregisterContainerInstance"
        ],
        "Resource": [
          "arn:aws:ecs:eu-west-2:${data.aws_caller_identity.account.account_id}:cluster/${aws_ecs_cluster.prometheus.name}"
        ]
      },
      {
      "Effect": "Allow",
      "Action": [
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:GetRepositoryPolicy",
        "ecr:DescribeRepositories",
        "ecr:ListImages",
        "ecr:DescribeImages",
        "ecr:BatchGetImage"
      ],
      "Resource": [
          "arn:aws:ecr:eu-west-2:${var.tools_account_id}:repository/platform-deployer-verify-metadata-exporter",
          "arn:aws:ecr:eu-west-2:${var.tools_account_id}:repository/platform-deployer-verify-cloudwatch-exporter",
          "arn:aws:ecr:eu-west-2:${var.tools_account_id}:repository/platform-deployer-verify-ecs-agent"
        ]
      },
      {
        "Effect": "Allow",
        "Action": [
          "ecr:GetAuthorizationToken",
          "ec2:DescribeInstances"
        ],
        "Resource": "*"
      }
    ]
  }
  EOF
}

resource "aws_iam_role_policy_attachment" "prometheus" {
  role       = aws_iam_role.prometheus.name
  policy_arn = aws_iam_policy.prometheus.arn
}

data "template_file" "prometheus_config" {
  template = file("${path.module}/files/prometheus/prometheus.yml")

  vars = {
    deployment = var.deployment
  }
}

data "template_file" "prometheus_cloud_init" {
  template = file("${path.module}/files/cloud-init/prometheus.sh")

  vars = {
    prometheus_config          = data.template_file.prometheus_config.rendered
    deployment                 = var.deployment
    domain                     = local.root_domain
    cluster                    = aws_ecs_cluster.prometheus.name
    ecs_agent_image_identifier = local.ecs_agent_image_identifier
    tools_account_id           = var.tools_account_id
    data_volume_size           = var.prometheus_volume_size
    cloudwatch_log_group       = aws_cloudwatch_log_group.fargate-logs.name
  }
}

resource "aws_instance" "prometheus" {
  count = var.number_of_prometheus_apps

  ami                  = data.aws_ami.ubuntu_focal.id
  instance_type        = "t3.large"
  subnet_id            = element(aws_subnet.internal.*.id, count.index)
  iam_instance_profile = aws_iam_instance_profile.prometheus.name
  user_data            = data.template_file.prometheus_cloud_init.rendered

  vpc_security_group_ids = [
    aws_security_group.prometheus.id,
    aws_security_group.scraped_by_prometheus.id,
    aws_security_group.can_connect_to_container_vpc_endpoint.id,
  ]

  root_block_device {
    volume_size = 20
  }

  tags = {
    Name       = "${var.deployment}-prometheus"
    Deployment = var.deployment
    Cluster    = "prometheus"
  }
}

resource "aws_ebs_volume" "prometheus" {
  count = var.number_of_prometheus_apps

  size      = var.prometheus_volume_size
  encrypted = true

  availability_zone = element(
    aws_subnet.internal.*.availability_zone, count.index
  )

  tags = {
    Name       = "${var.deployment}-prometheus"
    Deployment = var.deployment
  }
}

resource "aws_volume_attachment" "prometheus_prometheus" {
  count = var.number_of_prometheus_apps

  device_name = "/dev/xvdp"
  volume_id   = element(aws_ebs_volume.prometheus.*.id, count.index)
  instance_id = element(aws_instance.prometheus.*.id, count.index)
}

resource "aws_lb_target_group" "prometheus" {
  count = var.number_of_prometheus_apps

  name     = "${var.deployment}-prometheus-${count.index}"
  port     = 9090
  protocol = "HTTP"
  vpc_id   = aws_vpc.hub.id

  health_check {
    path     = "/metrics"
    protocol = "HTTP"
    interval = 10
    timeout  = 5
  }
}

resource "aws_lb_target_group_attachment" "prometheus" {
  count = var.number_of_prometheus_apps

  target_group_arn = element(aws_lb_target_group.prometheus.*.arn, count.index)
  target_id        = element(aws_instance.prometheus.*.id, count.index)
  port             = 9090
}

resource "aws_lb_listener_rule" "prometheus_https" {
  count        = var.number_of_prometheus_apps
  listener_arn = aws_lb_listener.mgmt_https.arn
  priority     = 100 + count.index

  action {
    type = "forward"

    target_group_arn = element(aws_lb_target_group.prometheus.*.arn, count.index)
  }

  condition {
    host_header {
      values = ["prom-${count.index + 1}.*"]
    }
  }
}

module "prometheus_ecs_roles" {
  source = "./modules/ecs_iam_role_pair"

  deployment       = var.deployment
  service_name     = "prometheus"
  image_name       = "verify-prometheus"
  tools_account_id = var.tools_account_id
}

data "template_file" "prometheus_task_def" {
  count    = var.number_of_prometheus_apps
  template = file("${path.module}/files/tasks/prometheus.json")

  vars = {
    image_identifier = "${local.tools_account_ecr_url_prefix}-verify-prometheus@${var.prometheus_image_digest}"
    config_base64    = base64encode(data.template_file.prometheus_config.rendered)
    alerts_base64    = base64encode(file("${path.module}/files/prometheus/alerts.yml"))
    external_url     = "https://prom-${count.index + 1}.${local.mgmt_domain}"
    deployment       = var.deployment
    region           = data.aws_region.region.id
  }
}

resource "aws_ecs_task_definition" "prometheus" {
  count                 = var.number_of_prometheus_apps
  family                = "${var.deployment}-prometheus-${count.index + 1}"
  container_definitions = element(data.template_file.prometheus_task_def.*.rendered, count.index)
  execution_role_arn    = module.prometheus_ecs_roles.execution_role_arn
  network_mode          = "host"

  volume {
    name      = "tsdb"
    host_path = "/srv/prometheus/metrics2"
  }

  placement_constraints {
    type       = "memberOf"
    expression = "attribute:ecs.availability-zone == ${element(local.azs, count.index)}"
  }
}

resource "aws_ecs_service" "prometheus" {
  count               = var.number_of_prometheus_apps
  name                = "${var.deployment}-prometheus-${count.index + 1}"
  cluster             = aws_ecs_cluster.prometheus.id
  task_definition     = element(aws_ecs_task_definition.prometheus.*.arn, count.index)
  scheduling_strategy = "DAEMON"
}
