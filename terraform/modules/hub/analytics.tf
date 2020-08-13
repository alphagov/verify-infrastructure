# analytics
#
# frontend applications are run on the ingress asg

resource "aws_security_group" "analytics_task" {
  name        = "${var.deployment}-analytics-task"
  description = "${var.deployment}-analytics-task"

  vpc_id = aws_vpc.hub.id
}

locals {
  analytics_location_blocks = <<-LOCATIONS

  set $analytics "${var.analytics_endpoint}";
  location /analytics {
    proxy_set_header X-Forwarded-For $http_x_forwarded_for;
    proxy_pass $analytics/matomo.php?$args;
    proxy_connect_timeout 300s;
    proxy_send_timeout 300s;
    proxy_read_timeout 300s;
  }

  location /healthcheck {
    return 200;
  }

  LOCATIONS

  nginx_analytics_location_blocks_base64 = base64encode(local.analytics_location_blocks)
}

data "template_file" "analytics_task_def" {
  template = file("${path.module}/files/tasks/analytics.json")

  vars = {
    nginx_image_identifier = "${local.tools_account_ecr_url_prefix}-verify-nginx-tls@${var.nginx_image_digest}"
    location_blocks_base64 = local.nginx_analytics_location_blocks_base64
    deployment             = var.deployment
    region                 = data.aws_region.region.id
  }
}

module "analytics_ecs_roles" {
  source = "./modules/ecs_iam_role_pair"

  deployment       = var.deployment
  service_name     = "analytics"
  tools_account_id = var.tools_account_id
}

resource "aws_ecs_task_definition" "analytics" {
  family                = "${var.deployment}-analytics"
  container_definitions = data.template_file.analytics_task_def.rendered
  network_mode          = "awsvpc"
  execution_role_arn    = module.analytics_ecs_roles.execution_role_arn
}

resource "aws_security_group_rule" "analytics_task_egress_to_internet_over_https" {
  type      = "egress"
  protocol  = "tcp"
  from_port = 443
  to_port   = 443

  security_group_id = aws_security_group.analytics_task.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_ecs_service" "analytics" {
  name            = "${var.deployment}-analytics"
  cluster         = aws_ecs_cluster.ingress.id
  task_definition = aws_ecs_task_definition.analytics.arn

  desired_count                      = var.number_of_apps
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 100

  load_balancer {
    target_group_arn = aws_lb_target_group.ingress_analytics.arn
    container_name   = "nginx"
    container_port   = "8443"
  }

  network_configuration {
    subnets = aws_subnet.internal.*.id

    security_groups = [
      aws_security_group.analytics_task.id,
      aws_security_group.can_connect_to_container_vpc_endpoint.id,
    ]
  }
}

resource "aws_ecs_task_definition" "analytics_fargate" {
  family                   = "${var.deployment}-analytics-fargate"
  container_definitions    = data.template_file.analytics_task_def.rendered
  execution_role_arn       = module.analytics_ecs_roles.execution_role_arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
}

resource "aws_ecs_service" "analytics_fargate" {
  name            = "${var.deployment}-analytics"
  cluster         = aws_ecs_cluster.fargate-ecs-cluster.id
  task_definition = aws_ecs_task_definition.analytics_fargate.arn

  desired_count                      = var.number_of_apps
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 100

  load_balancer {
    target_group_arn = aws_lb_target_group.ingress_analytics.arn
    container_name   = "nginx"
    container_port   = "8443"
  }

  network_configuration {
    subnets = aws_subnet.internal.*.id

    security_groups = [
      aws_security_group.analytics_task.id,
      aws_security_group.hub_fargate_microservice.id,
      aws_security_group.can_connect_to_container_vpc_endpoint.id,
    ]
  }

  service_registries {
    registry_arn = aws_service_discovery_service.analytics_fargate.arn
    port         = 8443
  }
}

resource "aws_service_discovery_service" "analytics_fargate" {
  name = "${var.deployment}-analytics"

  description = "service discovery for ${var.deployment}-analytics-fargate instances"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.hub_apps.id

    dns_records {
      ttl  = 60
      type = "SRV"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 2
  }
}
