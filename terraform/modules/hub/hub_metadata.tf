# metadata
#
# frontend applications are run on the ingress asg

resource "aws_security_group" "metadata_task" {
  name        = "${var.deployment}-metadata-task"
  description = "${var.deployment}-metadata-task"

  vpc_id = aws_vpc.hub.id
}

data "template_file" "metadata_task_def" {
  template = file("${path.module}/files/tasks/metadata.json")

  vars = {
    deployment       = var.deployment
    image_identifier = "${local.tools_account_ecr_url_prefix}-verify-metadata@${var.hub_metadata_image_digest}"
  }
}

module "metadata_ecs_roles" {
  source = "./modules/ecs_iam_role_pair"

  deployment       = var.deployment
  service_name     = "metadata"
  tools_account_id = var.tools_account_id
  image_name       = "verify-metadata"
}

resource "aws_ecs_task_definition" "metadata" {
  family                = "${var.deployment}-metadata"
  container_definitions = data.template_file.metadata_task_def.rendered
  network_mode          = "awsvpc"
  execution_role_arn    = module.metadata_ecs_roles.execution_role_arn
}

resource "aws_ecs_service" "metadata" {
  name            = "${var.deployment}-metadata"
  cluster         = aws_ecs_cluster.ingress.id
  task_definition = aws_ecs_task_definition.metadata.arn

  desired_count                      = var.number_of_apps
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 100

  load_balancer {
    target_group_arn = aws_lb_target_group.ingress_metadata.arn
    container_name   = "nginx"
    container_port   = "8443"
  }

  network_configuration {
    subnets = aws_subnet.internal.*.id
    security_groups = [
      aws_security_group.metadata_task.id,
      aws_security_group.can_connect_to_container_vpc_endpoint.id,
    ]
  }

  ordered_placement_strategy {
    type  = "spread"
    field = "instanceId"
  }
}
