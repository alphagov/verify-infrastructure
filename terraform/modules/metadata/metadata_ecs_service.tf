data "aws_region" "region" {}

data "terraform_remote_state" "hub" {
  backend = "s3"

  config = {
    bucket = "govukverify-tfstate-${var.deployment}"
    key    = "hub.tfstate"
    region = "eu-west-2"
  }
}

data "template_file" "metadata_task_def" {
  template = file("${path.module}/files/metadata.json")

  vars = {
    deployment       = var.deployment
    region           = data.aws_region.region.id
    image_identifier = "${var.tools_account_id}.dkr.ecr.eu-west-2.amazonaws.com/platform-deployer-verify-metadata@${var.hub_metadata_image_digest}"
  }
}

resource "aws_ecs_task_definition" "metadata_fargate" {
  family                   = "${var.deployment}-metadata-fargate"
  container_definitions    = data.template_file.metadata_task_def.rendered
  network_mode             = "awsvpc"
  execution_role_arn       = data.terraform_remote_state.hub.outputs.metadata_ecs_execution_role_arn
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
}

resource "aws_ecs_service" "metadata_fargate" {
  name            = "${var.deployment}-metadata-from-metadata-pipeline"
  cluster         = data.terraform_remote_state.hub.outputs.fargate_ecs_cluster_id
  task_definition = aws_ecs_task_definition.metadata_fargate.arn

  desired_count                      = var.number_of_metadata_apps
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 100

  launch_type      = "FARGATE"
  platform_version = "1.4.0"

  load_balancer {
    target_group_arn = data.terraform_remote_state.hub.outputs.ingress_metadata_lb_target_group_arn
    container_name   = "nginx"
    container_port   = "8443"
  }

  network_configuration {
    subnets = data.terraform_remote_state.hub.outputs.internal_subnet_ids
    security_groups = [
      data.terraform_remote_state.hub.outputs.metadata_task_security_group_id,
      data.terraform_remote_state.hub.outputs.hub_fargate_microservice_security_group_id,
      data.terraform_remote_state.hub.outputs.can_connect_to_container_vpc_endpoint,
    ]
  }

  service_registries {
    registry_arn = aws_service_discovery_service.metadata_fargate.arn
    port         = 8443
  }
}

resource "aws_service_discovery_service" "metadata_fargate" {
  name = "${var.deployment}-metadata-from-metadata-pipeline"

  description = "service discovery for ${var.deployment}-metadata-fargate instances"

  dns_config {

    namespace_id = data.terraform_remote_state.hub.outputs.hub_apps_private_dns_namespace_id

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
