resource "aws_security_group" "egress_via_proxy" {
  name        = "${var.deployment}-egress-via-proxy"
  description = "${var.deployment}-egress-via-proxy"

  vpc_id = aws_vpc.hub.id
}

resource "aws_security_group_rule" "egress_to_proxy_task" {
  type     = "egress"
  protocol = "tcp"

  from_port = 8080
  to_port   = 8080

  # source is destination for egress rules
  source_security_group_id = aws_security_group.egress_proxy_task.id
  security_group_id        = aws_security_group.egress_via_proxy.id
}

# Egress proxy task has to be able to access the internet directly (HTTP)
resource "aws_security_group_rule" "egress_proxy_task_egress_to_internet_over_http" {
  type      = "egress"
  protocol  = "tcp"
  from_port = 80
  to_port   = 80

  security_group_id = aws_security_group.egress_proxy_task.id
  cidr_blocks       = ["0.0.0.0/0"]
}

# Egress proxy task has to be able to access the internet directly (HTTPS)
resource "aws_security_group_rule" "egress_proxy_task_egress_to_internet_over_https" {
  type      = "egress"
  protocol  = "tcp"
  from_port = 443
  to_port   = 443

  security_group_id = aws_security_group.egress_proxy_task.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "egress_proxy_ingress_from_tasks" {
  type     = "ingress"
  protocol = "tcp"

  from_port = 8080
  to_port   = 8080

  security_group_id        = aws_security_group.egress_proxy_task.id
  source_security_group_id = aws_security_group.egress_via_proxy.id
}

locals {
  event_emitter_api_gateway = split("/", replace(var.event_emitter_api_gateway_url, "https://", ""))
}

locals {
  egress_proxy_allowlist_list = [
    "sentry\\.tools\\.signin\\.service\\.gov\\.uk",          # Tools Sentry
    replace(local.event_emitter_api_gateway[0], ".", "\\."), # API Gateway
    var.splunk_hostname,                                     # Splunk
  ]

  egress_proxy_allowlist = join(" ", local.egress_proxy_allowlist_list)
}

data "template_file" "egress_proxy_task_def" {
  template = file("${path.module}/files/tasks/squid.json")

  vars = {
    allowlist_base64 = base64encode(local.egress_proxy_allowlist)
    image_identifier = "${local.tools_account_ecr_url_prefix}-verify-squid@${var.squid_image_digest}"
    deployment       = var.deployment
    region           = data.aws_region.region.id
  }
}

module "egress_proxy_ecs_roles" {
  source = "./modules/ecs_iam_role_pair"

  deployment       = var.deployment
  service_name     = "egress-proxy"
  tools_account_id = var.tools_account_id
  image_name       = "verify-squid"
}

resource "aws_ecs_task_definition" "egress_proxy_fargate" {
  family                = "${var.deployment}-egress-proxy-fargate"
  container_definitions = data.template_file.egress_proxy_task_def.rendered
  execution_role_arn    = module.egress_proxy_ecs_roles.execution_role_arn

  task_role_arn            = module.egress_proxy_ecs_roles.task_role_arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  cpu    = 256
  memory = 512
}

resource "aws_security_group" "egress_proxy_task" {
  name        = "${var.deployment}-egress-proxy-task"
  description = "${var.deployment}-egress-proxy-task"
  vpc_id      = aws_vpc.hub.id
}

resource "aws_ecs_service" "egress_proxy_fargate" {
  name            = "${var.deployment}-egress-proxy"
  cluster         = aws_ecs_cluster.fargate-ecs-cluster.id
  task_definition = aws_ecs_task_definition.egress_proxy_fargate.arn

  desired_count                      = var.number_of_egress_proxy_apps
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 100

  launch_type = "FARGATE"

  network_configuration {
    subnets = aws_subnet.internal.*.id
    security_groups = [
      aws_security_group.egress_proxy_task.id,
      aws_security_group.hub_fargate_microservice.id,
      aws_security_group.can_connect_to_container_vpc_endpoint.id,
    ]
  }

  service_registries {
    registry_arn = aws_service_discovery_service.egress_proxy_fargate.arn
  }
}

resource "aws_service_discovery_service" "egress_proxy_fargate" {
  name = "${var.deployment}-egress-proxy"

  description = "service discovery for ${var.deployment}-egress-proxy-fargate instances"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.hub_apps.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 2
  }
}

